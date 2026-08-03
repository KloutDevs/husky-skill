# Contributing to husky-skill

Thanks for helping out! This project has one hard rule: **zero runtime
dependencies**. Every hook must run with nothing but `git` and POSIX `sh`.

## Ground rules

1. **No dependencies.** If a change needs an npm package to *run*, it doesn't
   belong in a hook. Tooling (ESLint, Prettier, tsc) is detected and optional —
   never required.
2. **POSIX `sh`, not Bash.** No `[[ ]]`, no arrays, no `local` where avoidable.
   Target `/bin/sh` (dash), not `/bin/bash`.
3. **A hook never modifies the user's files.** No `--fix`, no `--write`, no
   `git add` from inside a hook.
4. **Zero network egress.** Use `node_modules/.bin/`, never `npx`.
5. **English for all user-facing output and comments.** The docs ship in English
   (primary) and Spanish (`README.es.md`).

## Local setup

Dogfood the hooks — this repo uses its own:

```sh
sh scripts/install.sh
```

Now your commits here are validated by the very hooks you're editing.

## Before you open a PR

- **Syntax-check every script:**
  ```sh
  for f in assets/hooks/* scripts/install.sh; do sh -n "$f" && echo "OK $f"; done
  ```
- **Lint (recommended):** run [ShellCheck](https://www.shellcheck.net/) —
  `shellcheck assets/hooks/* scripts/install.sh`.
- **Test the behavior you changed.** Stage a file that should trip the check and
  confirm the hook exits non-zero with a clear message.

## Commit messages

This repo enforces **Conventional Commits** (its own `commit-msg` hook does the
work):

```
type(scope): subject        # ≤72 chars
```

Types: `feat fix docs style refactor perf test build ci chore revert`.

## What makes a good PR

Small, focused, and defensible in review. If you add or change a check, say
**why** in the description — the hooks are opinionated on purpose, and every
opinion should be arguable.
