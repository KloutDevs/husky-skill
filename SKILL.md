---
name: husky-skill
description: >-
  Dependency-free Git hooks — pre-commit, commit-msg, pre-push — for any repo. A
  Husky / lint-staged / commitlint replacement in pure POSIX shell with zero npm
  dependencies, built for teams with strict dependency policies (fintech,
  healthcare, government). Use whenever the user wants git hooks, pre-commit
  checks, secret scanning, Conventional Commits / commit-message validation,
  staged-file linting (ESLint/Prettier), type-check/build/test gates before
  push, test-coverage enforcement, dependency-audit or monorepo hooks, or
  mentions Husky, lint-staged, commitlint, pre-commit, githooks — even
  implicitly ("fail commits if ESLint fails", "block secrets before push").
metadata:
  version: "2.0.0"
  tags: "git-hooks, husky, lint-staged, commitlint, pre-commit, commit-msg, pre-push, post-merge, secret-scanning, conventional-commits, eslint, prettier, typescript, monorepo, test-coverage, dependency-audit, posix-shell, zero-dependencies"
---

# Husky Skill

Enterprise-grade Git hooks with **zero npm dependencies**. Catch leaked secrets,
formatting issues, broken types and failing builds before they reach production
or GitHub — a Husky replacement for environments where the dependency tree is
policy (fintech, healthcare, government).

## Purpose

Prevent problematic code from entering the repository at four stages:

| Stage           | Hook          | Budget   | Role                                       |
| --------------- | ------------- | -------- | ------------------------------------------ |
| Before commit   | `pre-commit`  | <5s      | Fast feedback: secrets, lint, format       |
| Commit message  | `commit-msg`  | instant  | Audit trail: Conventional Commits          |
| Before push     | `pre-push`    | 30s–2min | Last gate: types, build, tests, coverage   |
| After merge     | `post-merge`  | instant  | Flag lockfile drift → suggest `npm install` |

**Design principle: a slow hook is a bypassed hook.** Heavy checks live in
`pre-push`, so every commit stays fast and nobody reaches for `--no-verify` by
reflex. **Hooks are a filter, not a gate** — `--no-verify` exists; CI is the
mandatory enforcement layer. Always run the same checks in CI.

## How Claude should use this skill

When the user asks to set up hooks in a repository:

1. Verify the target is a Git repo (`git rev-parse --show-toplevel`).
2. **Preview first** (optional but recommended): `sh scripts/install.sh --dry-run`
   shows exactly what would change without writing anything.
3. Install: `sh scripts/install.sh` from this skill's directory, with the target
   repo as the working directory (or `--root /path/to/repo` from anywhere). It is
   idempotent and backs up any existing hooks it would overwrite (`.bak`).
4. Confirm with `git config core.hooksPath` (must print `.githooks`) and
   `ls .githooks`.
5. If the repo has `package.json`, the installer wires a `prepare` script so
   teammates inherit hooks on `npm install`.
6. Suggest a smoke test: stage a file with an unformatted `console.log(` or
   commit with the message `test` and watch it get rejected.

To **customize** a check for a project: edit the copied files in the target
repo's `.githooks/` — plain POSIX shell, tracked in the repo, reviewable in PRs.
Do not edit this skill's `assets/hooks/` unless changing the defaults for all
future installs.

## What each hook does (summary)

- **pre-commit** (staged only): non-skippable secret scan · blocked `.env`/keys ·
  files >5MB · conflict markers · Prettier `--check` · ESLint `--max-warnings=0`.
  No `--fix` (never modifies your files), no `npx` (zero network egress).
- **commit-msg**: Conventional Commits (`type(scope)!: subject`, ≤72 chars), pure
  shell, no `commitlint`.
- **pre-push**: full `tsc --noEmit` · `npm run build` · `npm test` · optional
  coverage gate · optional `npm audit` (opt-in) · optional API-break heuristic.
- **post-merge**: warns when `package-lock.json`/`yarn.lock` changed after a pull,
  so you don't run stale dependencies.

## Full documentation

For hook-type reference, per-stack notes (React, NestJS, monorepos, Python
`pre-commit` framework), Husky v4→v9 migration, the optional coverage /
dependency-audit / API-break checks, commit-message internals, a matching
`commitlint.config.js`, a GitHub Actions CI example, and troubleshooting, see:

**→ [`references/full-guide.md`](references/full-guide.md)**

Optional drop-ins:
- [`references/commitlint.config.js`](references/commitlint.config.js) — mirrors the `commit-msg` rules for teams already on commitlint.
- [`references/ci-github-actions.yml`](references/ci-github-actions.yml) — run the same gates server-side.

## Escape hatches

```sh
SKIP_ESLINT=1 / SKIP_PRETTIER=1                            # on commit
SKIP_TYPESCRIPT=1 / SKIP_BUILD=1 / SKIP_TESTS=1 / SKIP_COVERAGE=1   # on push
ENABLE_AUDIT=1        # opt-in dependency audit (the only network check)
ENABLE_API_CHECK=1    # opt-in removed-public-export heuristic (warn only)
HUSKY=0 git commit                                         # skip everything
git commit --no-verify                                     # git-native bypass
```

The secret scan has **no skip variable** — a leaked credential is an incident,
not a style choice.

## Requirements

Git ≥2.9 and POSIX `sh`. Node/ESLint/Prettier/TypeScript are detected and used
only if present.
