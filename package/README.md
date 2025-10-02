# make-packager

Action composta para compilar bibliotecas C com `make` (via include.mk) e gerar pacotes:

- Source tarball (`-src.tar.gz`)
- `.deb` e `.rpm` (Linux)
- `.zip` (Windows)
- `.tar.gz` (OpenBSD self-hosted)

## Uso

No repositório de uma biblioteca:

```yaml
name: CI

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest, windows-latest]

    steps:
      - uses: tty-pt/.github/actions/package@main
        with:
          name: qmap
          version: 1.2.3
          deps: "zlib,openssl"
```
