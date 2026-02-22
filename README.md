TTY-PT Packaging & CI

This repository contains Dockerfiles, VM images, and GitHub Actions used to build
and package MSYS2-like images and related artifacts.

Quick pointers
- Build targets: `docker/pkg-msys`, `docker/pkg-arch`, `docker/pkg-alpine`,
  `docker/pkg-ubuntu`, `docker/pkg-rocky`
- GitHub Actions: see `.github/workflows/all-in-one.yml` and
  `.github/workflows/aur.yml`
- Documentation: `docs/install.md`

Large artifacts
- This repository contains large binary artifacts (examples):
  - `docker/pkg-msys/msys-builder.tar.zst`
  - `docker/pkg-msys/msys2-base-x86_64-20250830.tar.zst`
  - `docker/pkg-msys/win10.qcow2`
  - `vms/alpine/alpine.qcow2` and `vms/alpine/alpine-standard-3.22.1-x86_64.iso`

  These files increase clone size and make CI slower. Recommended approaches:
  1) Use GitHub Releases or external storage for large blobs and reference them
     from this repository.
  2) Enable Git LFS for future large files (non‑destructive). Example:
     ```
     git lfs install
     # add patterns to .gitattributes (see repository .gitattributes)
     ```
  3) If you need to permanently remove existing large files from history,
     use `git filter-repo` or BFG — note this rewrites history and requires a
     force-push and coordination with collaborators.

License
- BSD-2-Clause (see `LICENSE`)

If something is unclear or you want me to prepare the Git LFS config or a
history-rewrite plan, tell me which option you prefer and I will prepare the
next steps.
