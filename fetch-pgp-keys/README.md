# fetch-pgp-keys

Fetch PGP public keys in $validpgpkeys in PKGBUILD and export ascii content in ./keys/pgp folder next to PKGBUILD

## Inputs

- directory

        The directory contains PKGBUILD.
        
        Required: true
        
## Outputs

- validpgpkeys

        The space splitted fingerprints.
        
        Example:
        
        111111111111111111111111111111111111 22222222222222222222222222222222222222222222
        
## Usage

```yaml
- name: Fetch GnuPG keys
  id: fetch-pgp-keys
  uses: arenekosreal/pkgbuild-actions/fetch-pgp-keys@v0.1.0
  with:
    directory: ./package
```

Then you can find public keys in ascii format at `./package/keys/pgp` directory with name like `<fingerprint>.asc`.
