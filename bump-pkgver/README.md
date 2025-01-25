# bump-pkgver

Bump $pkgver by running pkgver()

## Inputs

- directory

        The directory contains PKGBUILD.
        
        Required: true
        
- env

        The newline splitted KEY=VALUE pairs which will be used as environment variable.
        
        Required: false
        
        Note: Each line does not match KEY=VALUE pattern will be ignored.
        
- repo

        The path to custom pacman repository to storage extra dependencies.
        
        Required: false
        
        Note: You can use `update-pacman-repo` action to generate one.

- args

        Extra arguments passed to makepkg

        Required: false
        
## Outputs

- updated

        A boolean string which represents if PKGBUILD is updated.
        
## Usage

```yaml
- name: Bump pkgver in PKGBUILD
  id: bump-pkgver
  uses: arenekosreal/pkgbuild-actions/bump-pkgver@v0.1.0
  with:
    directory: ./package
    env: |
      PACKAGER="Me <me@example.com>"
    repo: my-custom-repo
    args: --ignorearch
```
