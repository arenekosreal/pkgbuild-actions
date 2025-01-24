# get-global-variable

Get top-level variable defined in PKGBUILD.

## Inputs

- directory

        The directory contains PKGBUILD.
        
        Required: true
        
- name

        The name of variable.
        
        Required: true
        
## Outputs

- value

        The value of name in PKGBUILD. Multiple values are splitted with space.
        
## Usage

```yaml
- name: Get PKGBUILD value
  id: get-global-variable
  uses: arenekosreal/pkgbuild-actions/get-global-variable@v0.1.0
  with:
    directory: ./package
    name: pkgbase
```

Then you can find value with `${{ steps.get-global-variable.outputs.value }}`.
