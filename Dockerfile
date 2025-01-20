# x86_64
FROM --platform=linux/amd64 archlinux:base-devel
RUN useradd -r -d /build builder && \
    mkdir -p /pkgdest /srcdest && \
    chown builder:builder /pkgdest /srcdest && \
    echo 'builder ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/100-builder
COPY entrypoint.sh /entrypoint.sh

# aarch64
FROM --platform=linux/arm64 curl:latest AS bootstrapper
USER root
ARG ALARM_URL=http://os.archlinuxarm.org
RUN mkdir /alarm && \
    curl -LO "${ALARM_URL}/os/ArchLinuxARM-aarch64-latest.tar.gz" && \
    tar -xpf ArchLinuxARM-aarch64-latest.tar.gz -C /alarm && \
    sed -i "1 i Server = ${ALARM_URL}/\$arch/\$repo" /alarm/etc/pacman.d/mirrorlist
FROM --platform=linux/arm64 scratch
COPY --from=bootstrapper /alarm/ /
RUN pacman-key --init && \
    pacman-key --populate && \
    pacman -Syu --noconfirm && \
    pacman -S base-devel --noconfirm --needed --asdeps
# https://gitlab.archlinux.org/archlinux/archlinux-docker/blob/master/README.md#principles
# https://wiki.archlinux.org/title/Pacman/Package_signing#Resetting_all_the_keys
RUN rm -rf /etc/pacman.d/gnupg /var/cache/pacman && \
    sed -i "1 d" /etc/pacman.d/mirrorlist
CMD ["/usr/bin/bash"]
# archlinuxlarm:base-devel should be ready here
# Followed template from https://gitlab.archlinux.org/archlinux/archlinux-docker/-/blob/master/Dockerfile.template
RUN useradd -r -d /build builder && \
    mkdir -p /pkgdest /srcdest && \
    chown builder:builder /pkgdest /srcdest && \
    echo 'builder ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/100-builder
COPY entrypoint.sh /entrypoint.sh
