# x86_64
FROM --platform=linux/amd64 archlinux:base-devel AS X64
RUN useradd -r -d /build builder && \
    mkdir -p /pkgdest /srcdest && \
    chown builder:builder /pkgdest /srcdest && \
    echo 'builder ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/100-builder
COPY entrypoint.sh /entrypoint.sh

# aarch64
FROM --platform=linux/arm64 curlimages/curl:latest AS downloader-ARM64
USER root
ARG ALARM_URL=http://os.archlinuxarm.org
RUN mkdir /alarm && \
    curl -LO "${ALARM_URL}/os/ArchLinuxARM-aarch64-latest.tar.gz" && \
    tar -xpf ArchLinuxARM-aarch64-latest.tar.gz -C /alarm && \
    sed -i "1 i Server = ${ALARM_URL}/\$arch/\$repo" /alarm/etc/pacman.d/mirrorlist
FROM --platform=linux/arm64 scratch AS bootstrapper-ARM64
COPY --from=downloader-ARM64 /alarm/ /
RUN pacman-key --init && \
    pacman-key --populate && \
    pacman -Syu --noconfirm
# https://github.com/agners/archlinuxarm-docker/blob/master/pacstrap-docker
RUN mkdir -p /alarm/var/lib/pacman && \
    pacman -r /alarm -Sy base base-devel --noconfirm && \
    pacman -r /alarm -D --asdeps base-devel && \
    rm -rf /alarm/etc/pacman.d/gnupg /alarm/var/cache/pacman
# https://gitlab.archlinux.org/archlinux/archlinux-docker/blob/master/README.md#principles
# https://wiki.archlinux.org/title/Pacman/Package_signing#Resetting_all_the_keys
FROM --platform=linux/arm64 scratch as ARM64
COPY --from=bootstrapper-ARM64 /alarm/ /
CMD ["/usr/bin/bash"]
# archlinuxlarm:base-devel should be ready here
# Followed template from https://gitlab.archlinux.org/archlinux/archlinux-docker/-/blob/master/Dockerfile.template
RUN useradd -r -d /build builder && \
    mkdir -p /pkgdest /srcdest && \
    chown builder:builder /pkgdest /srcdest && \
    echo 'builder ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/100-builder
COPY entrypoint.sh /entrypoint.sh
