# husky-skill · Full guide

Deep reference for the hooks, the optional checks, per-stack notes, migration
from Husky, CI parity, and troubleshooting. For the quick version see
[`../SKILL.md`](../SKILL.md) and [`../README.md`](../README.md).

## Git hook types (reference)

Git hooks are scripts that fire at points in the Git workflow. They live in
`.git/hooks/` and are **not** version-controlled by default — which is exactly
why `core.hooksPath` (pointing at a tracked `.githooks/`) is the whole trick.

| Hook                 | Fires when                          | husky-skill ships it? | Typical use                         |
| -------------------- | ----------------------------------- | :-------------------: | ----------------------------------- |
| `pre-commit`         | Before the commit is created        | ✅                    | Secrets, lint, format, staged checks |
| `prepare-commit-msg` | After default msg, before editor    | —                     | Auto-populate templates             |
| `commit-msg`         | After you write the message         | ✅                    | Enforce message format              |
| `post-commit`        | After the commit is created         | —                     | Notifications, logging              |
| `pre-push`           | Before pushing to a remote          | ✅                    | Types, build, tests, coverage       |
| `pre-rebase`         | Before a rebase starts              | —                     | Block rebase on protected branches  |
| `post-merge`         | After `git merge` / `git pull`      | ✅                    | Flag lockfile drift                 |
| `post-checkout`      | After `git checkout` / `switch`     | —                     | Rebuild assets, install deps        |

Want one we don't ship? Drop a POSIX-`sh` file with that name into your repo's
`.githooks/` — `core.hooksPath` picks it up automatically. Keep the same rules:
no auto-fix, no `npx`, tools optional.

## The four hooks in detail

### pre-commit (staged files only, target <5s)

1. **Secret scan** — added lines only. AWS keys, private-key blocks,
   Slack/OpenAI/GitHub/GitLab/Google tokens, JWTs, and `password = "…"`-style
   assignments. **Not skippable** — a leaked credential is an incident. False
   positive on a fixture? `git commit --no-verify` and tell the team.
2. **Forbidden filenames** — `.env*` (except `.env.example`), `.pem`, `.key`,
   `.p12`, `.jks`, keystores.
3. **Large files** — blocks >5MB (suggests Git LFS / `.gitignore`).
4. **Conflict markers** — unresolved `<<<<<<<` / `=======` / `>>>>>>>`.
5. **Prettier** `--check` on staged JS/TS. Skip: `SKIP_PRETTIER=1`.
6. **ESLint** `--max-warnings=0` on staged JS/TS. Skip: `SKIP_ESLINT=1`.

Deliberate choices, worth defending in review:

- **No `--fix`, no `--write`.** The hook never modifies files. Auto-fix + `git
  add` on a file with mixed staged/unstaged changes commits code you never
  reviewed — unacceptable in fintech. The hook fails; you run the fix, review,
  restage. This is the single biggest difference from most Husky setups.
- **`node_modules/.bin/` instead of `npx`.** `npx` may download from the network
  if a binary is missing locally. A hook must have zero egress: it runs only what
  is already installed and audited.
- **Tools are optional.** No ESLint installed → that check is skipped silently.
  The security checks (1–4) always run; they need only `git` + `sh`.

### commit-msg (pure shell, no commitlint)

Validates Conventional Commits: `type(scope)!: subject`.

- Types: `feat fix docs style refactor perf test build ci chore revert`
- Scope optional (`[a-z0-9-]`), `!` marks a breaking change
- First line ≤72 chars
- Auto-skips: merge commits, generated reverts, `fixup!`/`squash!`
- The rejection message prints valid examples — the error teaches the format

Already standardized on **commitlint** in CI? Drop in
[`commitlint.config.js`](commitlint.config.js) so the two never disagree. You
still don't need commitlint locally — the hook covers it dependency-free.

### pre-push (the heavy gate, 30s–2min)

1. **`tsc --noEmit`** on the whole project — cross-file type errors are invisible
   to staged-only checks. Skip: `SKIP_TYPESCRIPT=1`.
2. **`npm run build`** if the script exists. Skip: `SKIP_BUILD=1`.
3. **`npm test`** if a real test script exists (ignores npm's placeholder).
   Skip: `SKIP_TESTS=1`.
4. **Coverage gate** — runs `test:coverage` (or `coverage`) if that script
   exists. The **threshold lives where it belongs**: your `jest`/`vitest`/`nyc`
   config (`coverageThreshold` / `coverage.thresholds`). The runner enforces it
   and exits non-zero; the hook just guarantees it runs before a push. Skip:
   `SKIP_COVERAGE=1`.
5. **Dependency audit** — **opt-in**, `ENABLE_AUDIT=1`. Runs
   `npm audit --audit-level=high`. This is the **only** check that touches the
   network, so it is off by default to preserve zero-egress. Great for CI or a
   weekly local sweep.
6. **API-break heuristic** — **opt-in**, `ENABLE_API_CHECK=1`, **warn only**.
   Flags removed public `export`s in `*.d.ts` across the push range. It is a
   nudge, not a semver tool — if the removal is intentional, bump a major.

Pushing a branch deletion runs no checks (nothing to validate).

### post-merge

After a `git pull`/`merge`, warns if `package-lock.json` / `yarn.lock` /
`pnpm-lock.yaml` changed, so you don't run stale dependencies. It **never**
installs for you — a hook must not mutate your environment silently.

## Escape hatches (complete)

```sh
# pre-commit
SKIP_ESLINT=1 git commit
SKIP_PRETTIER=1 git commit

# pre-push
SKIP_TYPESCRIPT=1 git push
SKIP_BUILD=1 git push
SKIP_TESTS=1 git push
SKIP_COVERAGE=1 git push
ENABLE_AUDIT=1 git push        # opt-in network audit
ENABLE_API_CHECK=1 git push    # opt-in API-break warning

# everything
HUSKY=0 git commit             # skip all hooks (CI/Docker/emergency)
git commit --no-verify         # git-native full bypass
git push --no-verify
```

The `HUSKY=0` convention is kept for muscle-memory compatibility with teams
migrating from Husky. The **secret scan has no skip variable** by design.

## Per-stack notes

- **React/TS (Vite):** works out of the box; `build` runs `vite build`,
  `test:coverage` runs `vitest run --coverage`.
- **NestJS:** type-checking matters extra (decorators); `build` runs `nest build`.
- **Monorepo:** install at the Git root — `core.hooksPath` is per-repo, not
  per-package. For per-package linting, adapt `.githooks/pre-commit` to route
  staged paths to each workspace's linter (e.g. map `packages/api/**` → that
  package's ESLint config).
- **Windows:** Git for Windows ships a POSIX `sh`; hooks run under Git Bash
  automatically. GUI clients with a broken PATH? Rewrite the hook body in Node
  (`exec node .githooks/pre-commit.js`) — still zero deps.
- **Non-Node / polyglot repos:** the security checks (secrets, filenames, big
  files, conflict markers) are language-agnostic and run everywhere. For
  Python/Go/Rust linting you can either add branches to `.githooks/pre-commit`,
  or pair this with the Python [`pre-commit`](https://pre-commit.com/) framework
  for those languages while husky-skill owns the security + commit-msg layer.

## Migrating from Husky

1. `npm uninstall husky` and delete the `.husky/` directory.
2. Remove any `"prepare": "husky install"` from `package.json` (the installer
   adds `"prepare": "git config core.hooksPath .githooks"`).
3. Run `sh scripts/install.sh` (or `--root PATH`). Your old logic, if any, was
   in `.husky/pre-commit` etc. — port anything custom into `.githooks/`.
4. Husky v4 used `package.json` `"husky"` config; v9 uses files. husky-skill
   uses tracked files + `core.hooksPath`, so there is no config key to migrate —
   the hooks *are* the config.

Keeping `HUSKY=0` working means existing muscle memory and Docker/CI overrides
(`HUSKY=0`) keep functioning unchanged.

## CI parity

Hooks are a filter; CI is the gate. Run the same checks server-side where they
cannot be skipped. Copy [`ci-github-actions.yml`](ci-github-actions.yml) to
`.github/workflows/ci.yml`. Note the secret-scan step passes refs through `env:`
(never interpolate `${{ }}` straight into `run:`) to avoid workflow injection.

## Troubleshooting

- **"command not found" inside a hook** → the tool isn't in `node_modules/.bin`.
  Run `npm install`; hooks only use local binaries by design.
- **Hooks don't run after clone** → run `npm install` (fires `prepare`), or
  `git config core.hooksPath .githooks` manually.
- **Hook is slow** → pre-commit should stay <5s; if not, something heavy leaked
  in. Move it to pre-push. Never "fix" slowness by teaching people `--no-verify`.
- **Coverage step never runs** → you need a `test:coverage` (or `coverage`) npm
  script; the threshold lives in your test runner's config, not the hook.
- **GUI Git clients + nvm/fnm PATH issues** → source your version manager in the
  client's environment, or use the Node rewrite above.

## Uninstall

```sh
git config --unset core.hooksPath   # hooks stay in .githooks/ but stop running
```
