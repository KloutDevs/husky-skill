# Security Policy

## Reporting a vulnerability

Please **do not** open a public issue for security problems.

Report privately through GitHub's [Report a vulnerability](https://github.com/KloutDevs/husky-skill/security/advisories/new)
flow (Security → Advisories). We aim to acknowledge within **72 hours** and to
ship a fix or mitigation as fast as the severity warrants.

When reporting, please include:

- The hook or script affected (`pre-commit`, `commit-msg`, `pre-push`, `install.sh`).
- A minimal reproduction (staged content or command that triggers the issue).
- The impact you observed (e.g. a secret pattern that slips through, a command
  injection via a crafted filename or commit message).

## Scope

In scope:

- **Secret-scan bypasses** — a real credential pattern that the `pre-commit`
  scanner fails to catch on added lines.
- **Shell injection** — any path where a crafted filename, diff, or commit
  message can execute arbitrary commands inside a hook.
- **Silent installation failures** that leave a repo believing hooks are active
  when they are not.

## Important: what these hooks are (and are not)

> [!IMPORTANT]
> The secret scanner is a **filter, not a guarantee**. It uses pattern matching
> on *added lines* and will not catch every possible secret format. It reduces
> risk; it does not eliminate it.

- Hooks can always be bypassed with `--no-verify`. **CI is the mandatory gate** —
  run the same secret scan there, where it cannot be skipped by a developer.
- A hook that "passes" is not proof a commit is safe. Treat it as early
  feedback, and pair it with server-side enforcement, secret rotation, and code
  review.

## Supported versions

This project ships from `main`. Fixes land there; please test against the latest
commit before reporting.
