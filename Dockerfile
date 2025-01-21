# x86_64
FROM --platform=linux/amd64 archlinux:base-devel AS amd64

# aarch64
FROM curlimages/curl:latest AS downloader-arm64
USER root
ARG ALARM_URL=http://os.archlinuxarm.org
RUN mkdir /alarm && \
    curl -LO "${ALARM_URL}/os/ArchLinuxARM-aarch64-latest.tar.gz" && \
    tar -xpf ArchLinuxARM-aarch64-latest.tar.gz -C /alarm && \
    sed -i "1 i Server = ${ALARM_URL}/\$arch/\$repo" /alarm/etc/pacman.d/mirrorlist
FROM --platform=linux/arm64 scratch AS bootstrapper-arm64
COPY --from=downloader-arm64 /alarm/ /
RUN pacman-key --init && \
    pacman-key --populate && \
    pacman -Syu --noconfirm
# pacstrap seems not supports docker environment...
RUN mkdir -p /alarm/var/lib/pacman && \
    pacman -r /alarm -Sy base base-devel --noconfirm && \
    pacman -r /alarm -D --asdeps base-devel && \
    systemd-tmpfiles --create --root=/alarm && \
    rm -rf /alarm/etc/pacman.d/gnupg /alarm/var/cache/pacman
# https://gitlab.archlinux.org/archlinux/archlinux-docker/blob/master/README.md#principles
# https://wiki.archlinux.org/title/Pacman/Package_signing#Resetting_all_the_keys
FROM --platform=linux/arm64 scratch AS arm64
COPY --from=bootstrapper-arm64 /alarm/ /
CMD ["/usr/bin/bash"]
# archlinuxlarm:base-devel should be ready here
# Followed template from https://gitlab.archlinux.org/archlinux/archlinux-docker/-/blob/master/Dockerfile.template

FROM ${TARGETARCH} AS builder
RUN useradd -r -d /build builder && \
    mkdir -p /pkgdest /srcdest && \
    chown builder:builder /pkgdest /srcdest && \
    echo 'builder ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/100-builder
COPY entrypoint.sh /entrypoint.sh
