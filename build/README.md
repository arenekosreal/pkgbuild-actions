# build

Build PKGBUILD in a container.

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

## Outputs

- packages

        The newline splitted packages paths.
    
        Example:
        
        ./pkgdest/example-0.1.0-x86_64.pkg.tar.zst
        ./pkgdest/example-debug-0.1.0-x86_64.pkg.tar.zst
    
## Usage

```yaml
- name: Build PKGBUILD
    id: build
    uses: arenekosreal/pkgbuild-actions/build@v0.1.0
    with:
      directory: ./package
      env: |
          PACKAGER="Me <me@example.com>"
      repo: my-custom-repo
```
