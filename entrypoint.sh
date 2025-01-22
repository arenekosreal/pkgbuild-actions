#!/usr/bin/bash

set -e

# __log $level $msg
function __log() {
    if [[ $# -lt 2 ]]
    then
        __log error "Invalid arguments for __log. Expect >=2, got $#."
        return 1
    fi
    if [[ "$1" == "debug" ]]
    then
        echo "::$1::$2"
    else
        local -a context
        read -r -a context < <(caller)
        echo "::$1 file=${context[0]},line=${context[1]}::$2"
    fi
}

# __ensure_pkgbuild $dir
function __ensure_pkgbuild() {
    if [[ $# -lt 1 ]]
    then
        __log error "Invalid arguments for __ensure_pkgbuild. Expect >=1, got $#."
        return 1
    fi
    if [[ ! -f "$1/PKGBUILD" ]]
    then
        __log error "No PKGBUILD can be found at $1/"
        return 1
    fi
}

# __check_pacman_key
function __check_pacman_key() {
    __log notice "Checking pacman-key..."
    if [[ ! -d /etc/pacman.d/gnupg ]]
    then
        pacman-key --init
        pacman-key --populate
    fi
}

# __install_downloader $downloader
function __install_downloader() {
    if [[ $# -lt 1 ]]
    then
        __log error "Invalid arguments for __install_downloader. Expect >=1, got $#."
        return 1
    fi
    __check_pacman_key
    pacman -Sy
    local package
    package="$(pacman -Qoq "$1")"
    if [[ -z "$package" ]]
    then
        __log error "Unable to find package for downloader $1."
        return 2
    fi
    pacman -S "$package" --noconfirm --needed
}

# __invoke_downloader $downloader $url $filename
function __invoke_downloader() {
    if [[ $# -lt 3 ]]
    then
        __log error "Invalid arguments for __invoke_downloader. Expect >=3, got $#."
        return 1
    fi
    if type -t "$1" > /dev/null
    then
        case "$1" in
            wget)
                pushd "$SRCDEST"
                wget --tries=0 --retry-connrefused --retry-on-host-error -O "$3" "$2"
                popd
                ;;
            *)
                __log error "Unsupported downloader $1"
                return 1
        esac
    elif ! __install_downloader "$1"
    then
        __invoke_downloader "$1" "$2" "$3"
    else
        __log error "Unable to find downloader $1."
        return 1
    fi
}

# __append_extra_env $env
# WARN: Will modify existing SUDO variable.
# Use it in subshell instead.
function __append_extra_env() {
    if [[ $# -lt 1 ]]
    then
        __log error "Invalid arguments for __append_extra_env. Expect >=1, got $#."
        return 1
    fi
    local env_line
    while read -r env_line
    do
        if [[ "$env_line" =~ .+=.+ ]]
        then
            __log notice "Exporting environment $env_line now..."
            export "${env_line?}"
            SUDO+=" --preserve-env=$(echo "$env_line" | cut -d = -f 1 | xargs)"
        else
            __log debug "Invalid environment $env_line, skipping..."
        fi
    done <<< "$1"
}

# __prepare_build_environment $repo
function __prepare_build_environment() {
    if [[ $# -lt 1 ]]
    then
        __log error "Invalid arguments for __prepare_build_environment. Expect >=1, got $#."
        return 1
    fi
    __log notice "Syncing $SRCDEST_ROOT to $SRCDEST..."
    $SUDO cp -r "$SRCDEST_ROOT/." "$SRCDEST"
    __check_pacman_key
    if [[ -d keys/pgp ]]
    then
        __log notice "Importing GnuPG public keys..."
        # shellcheck disable=SC2086
        find keys/pgp -maxdepth 1 -mindepth 1 -type f -regex ".+\.asc$" -exec $SUDO gpg --import {} \;
    fi
    if [[ -n "$1" ]] && [[ -e "$GITHUB_WORKSPACE/$1/$1.db" ]] && [[ -e "$GITHUB_WORKSPACE/$1/$1.files" ]] && ! pacman-conf --repo="$1" > /dev/null
    then
        __log notice "Adding repository at $1..."
        echo -e "[$1]\nServer = file://$GITHUB_WORKSPACE/$1\nSigLevel = Optional TrustAll" | tee -a /etc/pacman.conf
    fi
    pacman -Sy
}

export BUILDDIR=/build PKGDEST=/pkgdest SRCDEST=/srcdest

declare PKGDEST_ROOT="$GITHUB_WORKSPACE$PKGDEST" \
        SRCDEST_ROOT="$GITHUB_WORKSPACE$SRCDEST"
mkdir -p "$SRCDEST_ROOT" "$PKGDEST_ROOT"



SUDO="/usr/bin/sudo -u builder \
           --preserve-env=BUILDDIR \
           --preserve-env=PKGDEST  \
           --preserve-env=SRCDEST  \
           --preserve-env=SOURCE_DATE_EPOCH"

# bump-pkgver $dir [$env] [$repo]
function bump-pkgver() {
    if [[ $# -lt 1 ]]
    then
        __log error "Invalid arguments for bump-pkgver. Expect >=1, got $#."
        return 1
    fi
    __ensure_pkgbuild "$1"
    pushd "$1"
    __prepare_build_environment "$3"
    __log notice "Copying PKGBUILD to a writable place..."
    local tmp
    tmp="$($SUDO mktemp -d -t "PKGBUILD-pkgver-XXXXXX")"
    $SUDO cp -r . "$tmp"
    pushd "$tmp"
    (
        __append_extra_env "$2"
        __log notice "Running makepkg now..."
        $SUDO /usr/bin/makepkg --syncdeps --nobuild
    )
    popd
    if diff -u "$tmp/PKGBUILD" ./PKGBUILD > /dev/null
    then
        echo "updated=false" >> "$GITHUB_OUTPUT"
    else
        echo "updated=true" >> "$GITHUB_OUTPUT"
        __log notice "Updating PKGBUILD with updated one..."
        cp "$tmp/PKGBUILD" ./PKGBUILD
    fi
    __log notice "Syncing $SRCDEST to $SRCDEST_ROOT..."
    cp -r --no-preserve=ownership "$SRCDEST/." "$SRCDEST_ROOT"
    popd
}

# build $dir [$env] [$repo]
function build() {
    if [[ $# -lt 1 ]]
    then
        __log error "Invalid arguments for build. Expect >=1, got $#."
        return 1
    fi
    __ensure_pkgbuild "$1"
    pushd "$1"
    __prepare_build_environment "$3"
    (
        __append_extra_env "$2"
        __log notice "Running makepkg now..."
        $SUDO /usr/bin/makepkg --syncdeps --holdver
    )
    __log notice "Syncing $SRCDEST to $SRCDEST_ROOT..."
    cp -r --no-preserve=ownership "$SRCDEST/." "$SRCDEST_ROOT"
    {
        local eof
        eof="$(dd if=/dev/urandom bs=15 count=1 status=none | base64)"
        echo "packages<<$eof"
        $SUDO /usr/bin/makepkg --packagelist | sed "s|$PKGDEST|$PKGDEST_ROOT|"
        echo "$eof"
    } >> "$GITHUB_OUTPUT"
    popd
    __log notice "Grabbing built packages..."
    local package
    while read -r package
    do
        __log notice "Copying $package to $PKGDEST_ROOT..."
        cp "$package" "$PKGDEST_ROOT"
    done < <($SUDO /usr/bin/maepkg --pacagelist)
    __log notice "You can find built package(s) at ${PKGDEST_ROOT//$GITHUB_WORKSPACE/.}"
}

# download-sources $dir $downloader
function download-sources() {
    if [[ $# -lt 2 ]]
    then
        __log error "Invalid arguments for download-sources. Expect >=2, got $#."
        return 1
    fi
    __ensure_pkgbuild "$1"
    pushd "$1"
    local source
    while read -r source
    do
        local url name
        local -a array
        # source=<name>::<url>
        if [[ "${source//::/}" != "$source" ]]
        then
            read -r -a array <<< "${source//::/ }"
            name="${array[0]}"
            url="${array[1]}"
        else
            url="$source"
            name="$(basename "$url")"
        fi
        unset array
        # url=<scheme>://<host>/<path>
        if [[ "${url//:\/\/}" != "$url" ]] && [[ -n "$name" ]] && ! [[ "$url" =~ ^(git|file) ]]
        then
            __log notice "Downloading $name with $url..."
            __invoke_downloader "$2" "$url" "$name"
        elif [[ "$url" =~ ^git ]]
        then
            __log error "Downloading git repository is not supported now."
            return 1
        fi
    done < <($SUDO /usr/bin/makepkg --printsrcinfo | grep source | cut -d = -f 2 | sed 's/^[[:space:]]*//')
    popd
}

# fetch-pgp-keys $dir
function fetch-pgp-keys() {
    if [[ $# -lt 1 ]]
    then
        __log error "Invalid arguments for fetch-pgp-keys. Expect >=1, got $#."
        return 1
    fi
    local -r FALLBACK_KEYSERVER="keyserver.ubuntu.com"
    __ensure_pkgbuild "$1"
    pushd "$1"
    local validpgpkeys
    validpgpkeys="$($SUDO /usr/bin/makepkg --printsrcinfo | grep validpgpkeys | cut -d = -f 2 | xargs)"
    mkdir -p keys/pgp
    __log notice "Fetching GnuPG key(s) $validpgpkeys from keyservers..."
    local -a fingerprints
    local fingerprint
    read -r -a fingerprints <<< "$validpgpkeys"
    for fingerprint in "${fingerprints[@]}"
    do
        echo "::notice file=$0,line=$LINENO::Fetching $fingerprint..."
        gpg --recv-keys "$fingerprint" || true
        if ! gpg --list-key "$fingerprint"
        then
            __log warning "Failed to fetch GnuPG keys with default keyserver, retrying with $FALLBACK_KEYSERVER..."
            gpg --recv-keys --keyserver "$FALLBACK_KEYSERVER" "$fingerprint"
            gpg --list-key "$fingerprint"
        fi
        gpg --export --armor -o "keys/pgp/$fingerprint.asc" "$fingerprint"
    done
    echo "validpgpkeys=$validpgpkeys" >> "$GITHUB_OUTPUT"
    popd
}

# update-pacman-repo $dir
function update-pacman-repo() {
    if [[ $# -lt 1 ]]
    then
        _log error "Invalid arguments for update-pacman-repo. Expect >=1, got $#."
        return 1
    fi
    pushd "$1"
    {
        local repo eof
        repo="$(basename "$1")"
        if [[ -z "$(ls -A)" ]]
        then
            /usr/bin/repo-add -q "$repo.db.tar.gz"
        fi
        eof="$(dd if=/dev/urandom bs=15 count=1 status=none | base64)"
        echo "packages<<$eof"
        find . -maxdepth 1 -mindepth 1 -type f \
            -regex '.+\.pkg\.tar\.[0-9a-zA-Z]+$' \
            -exec /usr/bin/repo-add -R -q "$repo.db.tar.gz" {} + \
            -printf "%f\n"
        echo "$eof"
    } >> "$GITHUB_OUTPUT"
    popd
    __log notice "Result of repo directory:"
    ls -l "$1"
}

# get-global-variable $dir $name
function get-global-variable() {
    if [[ $# -lt 2 ]]
    then
        __log error "Invalid arguments for get-global-variable. Expect >=2, got $#."
        return 1
    fi
    __ensure_pkgbuild "$1"
    pushd "$1"
    local -a lines
    local srcinfo
    srcinfo="$($SUDO /usr/bin/makepkg --printsrcinfo)"
    __log debug "SRCINFO is $srcinfo"
    read -r -a lines <<< "$(echo "$srcinfo" | grep -n pkgname | cut -d : -f 1)"
    local global_start=1
    local global_end
    global_end="$(( lines[0] - 1 ))"
    {
        eof="$(dd if=/dev/urandom bs=15 count=1 status=none | base64)"
        echo "value<<$eof"
        echo "$srcinfo" | sed -n "$global_start,${global_end}p" | grep "$2" | cut -d = -f 2- | xargs
        echo "$eof"
    } >> "$GITHUB_OUTPUT"
    popd
}

if [[ -n "$1" ]]
then
    if [[ "$1" =~ ^[^_] ]] && [[ "$(type -t "$1")" == "function" ]]
    then
        __log debug "Invoking action with arguments $*..."
        # shellcheck disable=SC2068
        $@
    else
        __log error "Unsupported action $1."
        __log debug "Type of action $1 is $(type -t "$1")."
        exit 2
    fi
else
    __log error "No action is provided."
    exit 2
fi
