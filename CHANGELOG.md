# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2026-08-03

### Added

- **`post-merge` hook** — warns when the dependency lockfile changed after a
  pull so you don't run stale dependencies (never installs for you).
- **Coverage gate** in `pre-push` — runs your `test:coverage`/`coverage` script;
  the threshold lives in your `jest`/`vitest`/`nyc` config. Skip: `SKIP_COVERAGE=1`.
- **Opt-in dependency audit** in `pre-push` (`ENABLE_AUDIT=1`) — `npm audit
  --audit-level=high`. The only check that touches the network, off by default.
- **Opt-in API-break heuristic** in `pre-push` (`ENABLE_API_CHECK=1`) — warns
  (never blocks) on removed public exports in `*.d.ts`.
- **`install.sh` flags** — `--dry-run` (preview, writes nothing) and `--root PATH`.
- **`references/full-guide.md`** — hook-type reference, per-stack notes,
  monorepos, Husky v4→v9 migration, CI parity, troubleshooting.
- **`references/commitlint.config.js`** — optional drop-in mirroring the
  `commit-msg` rules for teams already on commitlint (no dependency added).
- **`references/ci-github-actions.yml`** — example CI running the same gates,
  with injection-safe ref handling.
- **CI workflow** (`.github/workflows/ci.yml`) — dogfoods the hooks with
  ShellCheck + a secret-scan smoke test.
- Frontmatter `metadata` (version + keyword-dense tags) for discoverability.
- Bilingual documentation: `README.md` (English, primary) + `README.es.md`.
- Branded SVG assets: `assets/banner.svg` and `assets/demo.svg`.
- `CONTRIBUTING.md` and `SECURITY.md`.

### Changed

- `SKILL.md` slimmed to a progressive-disclosure overview; deep docs moved to
  `references/`.
- All hook output and comments translated to English (was Spanish).

### Notes

- The zero-dependency / no-autofix / zero-egress philosophy is unchanged. New
  network- or environment-touching behavior (audit) is strictly opt-in.

## [1.0.0] - 2026-08-02

### Added

- Initial release: `pre-commit` (secret scan, forbidden files, large files,
  conflict markers, Prettier, ESLint), `commit-msg` (Conventional Commits),
  and `pre-push` (type-check, build, test) hooks.
- `scripts/install.sh` with idempotent install + `prepare` wiring.
- MIT license.

[2.0.0]: https://github.com/KloutDevs/husky-skill/releases/tag/v2.0.0
[1.0.0]: https://github.com/KloutDevs/husky-skill/releases/tag/v1.0.0
