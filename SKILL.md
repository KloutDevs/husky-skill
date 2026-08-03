---
name: husky-skill
description: >-
  Set up dependency-free Git hooks (pre-commit, commit-msg, pre-push) in any
  repository — a Husky replacement with zero npm dependencies, built for teams
  with strict dependency policies (fintech, regulated environments). Use this
  skill whenever the user wants git hooks, pre-commit checks, commit message
  validation, secret scanning before commits, mentions Husky or lint-staged,
  or asks to block bad code from reaching GitHub/GitLab — even if they don't
  say "hook" explicitly (e.g. "I want commits to fail if ESLint fails").
---

# Husky Skill

Enterprise-grade Git hooks with **zero npm dependencies**. Catch bugs,
formatting issues, leaked secrets and broken builds before they reach
production or GitHub.

Built for environments where the dependency tree is policy — fintech,
healthcare, government — where you can't add Husky but you still need
everything Husky does.

## Purpose

Prevent problematic code from entering the repository at three stages:

| Stage | Hook | Budget | Role |
|---|---|---|---|
| Before commit | `pre-commit` | <5s | Fast feedback: lint, format, secrets |
| Commit message | `commit-msg` | instant | Audit trail: Conventional Commits |
| Before push | `pre-push` | 30s–2min | Last gate: types, build, tests |

**Design principle: a slow hook is a bypassed hook.** If `git commit` takes
30 seconds, within two weeks the whole team commits with `--no-verify` by
reflex, and your protection drops to zero. That's why heavy checks live in
`pre-push` — it still guarantees nothing broken *leaves the machine*, which
is the actual goal, without taxing every commit.

**Hooks are a filter, not a gate.** Anyone can bypass with `--no-verify`.
CI is the enforcement layer; hooks are developer experience. In regulated
environments, run the same checks in CI — always.

## How Claude should use this skill

When the user asks to set up hooks in a repository:

1. Verify the target is a Git repo (`git rev-parse --show-toplevel`).
2. Run `sh scripts/install.sh` from this skill's directory, with the target
   repo as the working directory. It is idempotent and backs up any
   existing hooks it would overwrite (`.bak`).
3. Confirm with `git config core.hooksPath` (must print `.githooks`) and
   `ls .githooks`.
4. If the repo has `package.json`, the installer wires a `prepare` script so
   teammates inherit hooks on `npm install`. If a `prepare` already exists,
   tell the user to merge `git config core.hooksPath .githooks` into it.
5. Suggest a smoke test: stage a file with `console.log(` unformatted code
   or commit with the message `test` and watch it get rejected.

To **customize** a check for a project (e.g. Bliim only allows ESLint +
Prettier): edit the copied files in the target repo's `.githooks/` — they
are plain POSIX shell, tracked in the repo, reviewable in PRs. Do not edit
this skill's `assets/hooks/` unless the user wants to change the defaults
for all future installs.

To **uninstall**: `git config --unset core.hooksPath` (hooks stay in
`.githooks/` but stop running).

## What each hook does

### pre-commit (staged files only)

1. **Secret scan** — AWS keys, private key blocks, Slack/OpenAI/GitHub/
   GitLab/Google tokens, JWTs, and `password = "..."`-style assignments in
   *added lines only*. **Not skippable** — a leaked credential is an
   incident, not a style choice. False positive? `--no-verify` + tell the
   team.
2. **Forbidden filenames** — `.env*` (except `.env.example`), `.pem`,
   `.key`, `.p12`, `.jks`, keystores.
3. **Large files** — blocks >5MB (suggests Git LFS / .gitignore).
4. **Conflict markers** — unresolved `<<<<<<<` / `=======` / `>>>>>>>`.
5. **Prettier** `--check` on staged JS/TS. Skip: `SKIP_PRETTIER=1`.
6. **ESLint** `--max-warnings=0` on staged JS/TS. Skip: `SKIP_ESLINT=1`.

Deliberate choices, worth defending in review:

- **No `--fix`, no `--write`.** The hook never modifies files. Auto-fix +
  `git add` on a file with mixed staged/unstaged changes commits code you
  never reviewed — unacceptable in fintech. The hook fails; you run
  `npm run lint:fix`, review, restage.
- **`node_modules/.bin/` instead of `npx`.** `npx` may download packages
  from the network if not found locally. A hook must have zero egress: it
  only runs what's already installed and audited.
- **Tools are optional.** No ESLint installed → that check is skipped
  silently. The security checks (1–4) always run; they need only git+sh.

### commit-msg (pure shell, no commitlint)

Validates Conventional Commits: `type(scope)!: subject`.

- Types: `feat fix docs style refactor perf test build ci chore revert`
- Scope optional (`[a-z0-9-]`), `!` marks breaking changes
- First line ≤72 chars
- Auto-skips: merge commits, generated reverts, `fixup!`/`squash!`
- Rejection message shows valid examples — the error teaches the format

### pre-push (the heavy gate)

1. **`tsc --noEmit`** on the *whole project* — cross-file type errors are
   invisible to staged-only checks; this is where they get caught.
   Skip: `SKIP_TYPESCRIPT=1`.
2. **`npm run build`** if the script exists — tsc doesn't catch bundler
   errors, bad asset imports, or env misconfig. Skip: `SKIP_BUILD=1`.
3. **`npm test`** if a real test script exists (ignores npm's default
   placeholder). Skip: `SKIP_TESTS=1`.
4. Pushing a branch deletion runs no checks (nothing to validate).

## Escape hatches

```sh
SKIP_ESLINT=1 git commit          # skip one check
SKIP_PRETTIER=1 git commit
SKIP_TYPESCRIPT=1 git push
SKIP_BUILD=1 git push
SKIP_TESTS=1 git push

HUSKY=0 git commit                # skip all hooks (CI/Docker/emergency)
git commit --no-verify            # git-native full bypass
git push --no-verify
```

The `HUSKY=0` convention is kept for muscle-memory compatibility with
teams migrating from Husky.

## Per-stack notes

- **React/TS (e.g. Vite):** works out of the box; `build` runs `vite build`.
- **NestJS:** type-check matters extra (decorators); `build` runs `nest build`.
- **Monorepo:** install at the Git root. `core.hooksPath` is per-repo, not
  per-package. For per-package linting, adapt `.githooks/pre-commit` to
  route staged paths to each workspace's linter.
- **Windows:** Git for Windows ships a POSIX sh — hooks run under Git Bash
  automatically. If a team uses GUI clients with broken PATH, rewrite the
  hook body in Node (`exec node .githooks/pre-commit.js`) — still zero deps.

## Troubleshooting

- **"command not found" inside a hook** → tool not in `node_modules/.bin`.
  Run `npm install`; the hook only uses local binaries by design.
- **Hooks don't run after clone** → run `npm install` (fires `prepare`), or
  manually `git config core.hooksPath .githooks`.
- **Hook is slow** → pre-commit should stay <5s; if not, something heavy
  leaked into it. Move it to pre-push. Never "fix" slowness by teaching
  people `--no-verify`.
- **GUI Git clients + nvm/fnm PATH issues** → source your version manager
  in the client's environment, or use the Node rewrite above.

## Requirements

Git ≥2.9 and POSIX sh. That's it. Node/ESLint/Prettier/TypeScript are
detected and used only if present.

## License

MIT
