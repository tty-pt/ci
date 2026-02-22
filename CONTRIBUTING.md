Contributing

Thank you for contributing. This document explains basic workflow conventions,
how we handle large artifacts, and how to run the fetch helper.

Branching & commits
- Create branches from `main`: `feature/<short>`, `fix/<short>`, `chore/<short>`.
- Keep commits focused and write conventional messages (e.g. `feat:`, `fix:`,
  `chore:`).

Tests & CI
- Workflows: `.github/workflows/*` — run CI in PRs.
- Where possible, run Docker builds locally before opening PRs.

Large artifacts policy
- Do NOT commit large binaries directly to the repository. Instead:
  1) Upload large build artifacts to GitHub Releases (or external storage).
  2) Add SHA256 checksums to `CHECKSUMS` and verify them via
     `scripts/fetch-artifacts.sh`.
  3) If you need to add a large file in-tree temporarily, coordinate on an
     Issue and ensure a maintainer approves; prefer LFS for future files.

Releases
- Tag releases with semantic versions and upload built artifacts to the
  Release as assets. Include checksums and optional GPG signatures.

Security
- Never commit private keys, passwords, or secrets. If a secret is accidentally
  committed, open an Issue and coordinate a remediation (rotate secret,
  remove from history if necessary).

Fetching artifacts
- Use `scripts/fetch-artifacts.sh` to download assets from a Release and
  verify checksums. The script requires `jq` and `sha256sum`.

Contact
- Open an Issue for major changes (history rewrite, switching storage for
  artifacts, or enabling an automated artifact publisher).
