# update-pacman-repo

Scan packages and create/update a pacman repository

## Inputs

- directory

        The directory contains PKGBUILD.
        
        Required: true
        
## Outputs

- packages

        The newline splitted paths of packages added.
        
## Usage

```yaml
- name: Generate pacman repository
  id: update-pacman-repo
  uses: arenekosreal/pkgbuild-actions/update-pacman-repo@v0.1.0
  with:
    directory: ./repository
```