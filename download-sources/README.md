# download-sources

Download $sources in PKGBUILD with customized program

## Inputs

- directory

        The directory contains PKGBUILD.
        
        Required: true
        
- downloader

        The program to download sources.
        
        Required: false
        
        Default: wget
        
        Note: Only wget is supported currently.
        
## Outputs

        None
        
## Usage

```yaml
- name: Download Sources
  id: download-sources
  uses: arenekosreal/pkgbuild-actions/download-sources@v0.1.0
  with:
    directory: ./package
    downloader: wget
```

Then you can find downloaded sources at `./srcdest`, which will be used as `/srcdest` in container for building.

You can also setup `actions/cache` to cache this folder to speedup building next time.
