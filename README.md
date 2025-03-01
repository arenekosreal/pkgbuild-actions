# pkgbuild-actions

A series of GitHub Actions useful for building Arch Linux's PKGBUILD files in GitHub Action.

> [!IMPORTANT]
> pkgbuild-actions is deprecated due to its complexity.
> If you are looking for an alternative, you can check [makepkg-action](https://github.com/arenekosreal/makepkg-action).
> But it requires manual migration.

## CI status

[![Build container image, publish to ghcr.io and test actions](https://github.com/arenekosreal/pkgbuild-actions/actions/workflows/ci.yml/badge.svg?event=push)](https://github.com/arenekosreal/pkgbuild-actions/actions/workflows/ci.yml)

## Features

- Multi-arch support

    You can handle `x86_64` and `aarch64` packages with those actions.
    
    How to use: 
    
    Set `runs-on` with proper value like `ubuntu-24.04` or `ubuntu-24.04-arm`. 
    The latter will only available for public repository.
    You can also run the docker image directly with `--platform` argument to specify which architecture you want to run.

- No yay/paru

    Everything is built with a minimal archlinux/archlinuxarm system with `base-devel`, `base` and other dependencies listed in PKGBUILD installed.
    Not-in-official-repository dependencies will be installed from a custom repository so pacman can find it directly.
    
    This means you have to prepare a custom pacman repository yourself to storage those dependencies.
    You can use `update-pacman-repo` action in this github repository to achieve that.

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
