# TODO

## Recover signed manifests for brew

**Status: want this back. Partially restored, still incomplete.**

Brew manifests used to be GPG-signed. They no longer are.

### History

- `f296615` (MacOS, 2025-10-03) introduced the brew publish action with a
  "Create versioned directory structure" step doing `mkdir -p
  repo/versions/$VERSION`, and a signing step that cd'd there and
  `--detach-sign`ed `SHA256SUMS`. Brew manifests were genuinely signed.
- `f6e415a` (Separate dist directories) moved the tree to
  `repo/macos/versions/$VERSION` and kept signing it.
- `8ef5819` (Multi-arch support + OpenBSD) merged the macOS action into
  `publish/action.yml` and dropped the `mkdir`. The signing step survived,
  still `cd`ing into `repo/versions/$VERSION` — a directory nothing creates.
  `&&` short-circuited, `|| true` swallowed it, exit code 0. **Every brew
  release since has published an unsigned manifest and reported success.**
  Verified by running the old snippet verbatim against a real throwaway key:
  the `cd` fails, no `.asc` is written, the step still exits 0.

### Where it stands now

`20d8df2` restores the signing: it creates `repo/versions/$VERSION`, builds
the manifest from that version's files, and signs it. Verified end to end
with a throwaway key — `Good signature`.

What is still missing is **delivery**. The brew upload only pushes `repo/`'s
top level, so the manifest and its signature stay on the runner and never
reach the host. Restoring the signature properly means:

1. Decide the on-host layout. The obvious one is to keep publishing to
   `/var/www/htdocs/brew/` flat (filenames are already versioned) *plus* a
   `versions/<v>/SHA256SUMS` + `SHA256SUMS.asc` + `key.pub` tree, and push
   that tree rather than letting each release overwrite the flat root
   `SHA256SUMS`, which now describes only the current build.
2. Decide who verifies it. As of 2026-10 nothing consumes
   `/var/www/htdocs/brew/`: all 37 formulae in `tty-pt/tap` fetch the GitHub
   release asset and carry an inline sha256, and the GitHub release already
   publishes a signed `CHECKSUMS.asc`. So the brew artifacts *are* signed and
   verified today — just through the release, not the host mirror. A signed
   manifest on the host is only worth restoring if something starts reading
   it, or if the host is meant to be an independent archive.

Point 2 is the real decision; point 1 is mechanical once it is made.
