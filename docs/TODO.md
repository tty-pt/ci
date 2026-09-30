# TODO

## Signed brew manifests

**Status: signing restored and confirmed on a real release.**

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
  release between then and `20d8df2` published an unsigned manifest and
  reported success.** Confirmed by running the old snippet verbatim against a
  real throwaway key: the `cd` fails, no `.asc` is written, exit 0.

### Fixed in `20d8df2`

Creates `repo/versions/$VERSION`, builds the manifest from that version's
files only, and signs it. The `|| true` is gone: a signing failure now
prints a warning instead of passing silently, but still does not fail the
publish, since an unsigned mirror is still usable.

### Confirmed working

nd-level `v1.0.1`, run `36791525891`, publish job `110145828263`:
`versions/1.0.1/SHA256SUMS.asc` was produced and the subsequent `Update repo`
transferred 13 files including `versions/1.0.1/SHA256SUMS` and
`versions/1.0.1/SHA256SUMS.asc`. Signature and manifest are on the host.

### Open

1. **Nothing consumes the signed manifest.** All 37 formulae in `tty-pt/tap`
   fetch the GitHub release asset and carry an inline sha256; the release
   also publishes its own signed `CHECKSUMS.asc`. So the signature is
   published and verifiable by hand, but no client checks it. Worth deciding
   whether the host mirror is meant to be an independently verifiable archive
   (in which case document how to verify) or just a file cache (in which case
   the signing is belt-and-braces and that's fine).

2. **The flat root `SHA256SUMS` is now ambiguous.** For brew, `Prepare repo
   folder` no longer pulls the mirror down, so the manifest it computes at
   publish/action.yml:201 covers only the current build, while the host's
   pre-existing copy covers the full history. rsync's size+mtime check means
   the host file is *not* being truncated in practice — the new one is
   written into a different byte range and left alone. But the two files have
   the same path and different meanings. If the mirror should have one
   authoritative manifest, generate it on the host:

   ```
   ssh <host> 'cd /var/www/htdocs/brew && find . -type f \
     -not -name "SHA256SUMS*" -not -name "key.pub" | sort | xargs sha256sum'
   ```

   which returns tens of KB of text rather than transferring artifacts, then
   sign that locally and push it. Not done because nothing reads the file.

3. **The mirror grows without bound.** Every release adds artifacts to
   `/var/www/htdocs/brew/` and nothing prunes old versions, which is why the
   download had reached 527 files. Whatever is decided about the manifest, a
   retention policy for old versions would keep this from recurring.
