# pkgbuild-actions

A series of GitHub Actions useful for building Arch Linux's PKGBUILD files in GitHub Action.

## Actions

- build

    Build PKGBUILD in container.

- bump-pkgver

    Bump `$pkgver` by running `pkgver()` in PKGBUILD.

- download-sources

    Download files defined in `$sources` array.

- fetch-pgp-keys

    Fetch GnuPG keys defiled in `$validpgpkeys` array.

- get-global-variable

    Get top-level variables defined in PKGBUILD.

- update-pacman-repo

    Scan `*.pkg.tar.*` in directory and generate a pacman repository.

## Usage

See `README.md` in each action's folder.
