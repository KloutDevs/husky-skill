#!/bin/sh
# husky-skill · install.sh
# Installs the hooks into a Git repo. Idempotent: running it twice breaks
# nothing. Zero dependencies: just git + sh.
#
# Usage:
#   sh scripts/install.sh                 # install into the current repo
#   sh scripts/install.sh --root PATH     # install into the repo at PATH
#   sh scripts/install.sh --dry-run       # show what would change, write nothing
#   sh scripts/install.sh --help
#
# What it does:
#   1. Verifies the target is a Git repo
#   2. Copies assets/hooks/* → .githooks/ in the target repo
#   3. git config core.hooksPath .githooks
#   4. Ensures execute permissions
#   5. (optional) adds a "prepare" script to package.json if present and absent

set -e

DRY_RUN=0
ROOT=''

usage() {
  sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --root) ROOT="$2"; shift ;;
    --root=*) ROOT="${1#--root=}" ;;
    -h|--help) usage 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; usage 1 ;;
  esac
  shift
done

SKILL_DIR=$(unset CDPATH; cd -- "$(dirname -- "$0")/.." && pwd)
HOOKS_SRC="$SKILL_DIR/assets/hooks"

if [ -t 1 ]; then
  GREEN=$(printf '\033[0;32m'); YELLOW=$(printf '\033[0;33m')
  RED=$(printf '\033[0;31m'); BLUE=$(printf '\033[0;34m'); NC=$(printf '\033[0m')
else
  GREEN=''; YELLOW=''; RED=''; BLUE=''; NC=''
fi

# In dry-run, prefix every action line so it's unmistakable
say() { [ "$DRY_RUN" = "1" ] && printf '%s[dry-run]%s %s\n' "$BLUE" "$NC" "$1" || printf '%s\n' "$1"; }

# 1. Resolve the target Git repo (honour --root)
if [ -n "$ROOT" ]; then
  GIT_ROOT=$(git -C "$ROOT" rev-parse --show-toplevel 2>/dev/null) || {
    printf '%s✖ %s is not inside a Git repository.%s\n' "$RED" "$ROOT" "$NC" >&2; exit 1; }
else
  GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
    printf '%s✖ You are not inside a Git repository.%s\n' "$RED" "$NC" >&2
    printf '  Run this from the project root, or pass --root PATH.\n' >&2; exit 1; }
fi

[ -d "$HOOKS_SRC" ] || { printf '%s✖ Cannot find %s%s\n' "$RED" "$HOOKS_SRC" "$NC" >&2; exit 1; }

DEST="$GIT_ROOT/.githooks"
say "Target repo: $GIT_ROOT"
[ "$DRY_RUN" = "1" ] || mkdir -p "$DEST"

# 2. Copy hooks (with backup if the destination differs)
for hook in "$HOOKS_SRC"/*; do
  name=$(basename "$hook")
  target="$DEST/$name"
  if [ -f "$target" ] && ! cmp -s "$hook" "$target"; then
    say "back up existing $name → $name.bak"
    [ "$DRY_RUN" = "1" ] || cp "$target" "$target.bak"
  fi
  say "install hook: .githooks/$name"
  [ "$DRY_RUN" = "1" ] || { cp "$hook" "$target"; chmod +x "$target"; }
done

# 3. Point Git at the folder (idempotent)
CURRENT=$(git -C "$GIT_ROOT" config --local core.hooksPath 2>/dev/null || true)
if [ "$CURRENT" != ".githooks" ]; then
  say "set core.hooksPath → .githooks"
  [ "$DRY_RUN" = "1" ] || { git -C "$GIT_ROOT" config core.hooksPath .githooks; printf '%s✔ core.hooksPath → .githooks%s\n' "$GREEN" "$NC"; }
else
  printf '%s· core.hooksPath was already configured%s\n' "$YELLOW" "$NC"
fi

# 4. Suggest/add a prepare script so the team inherits the hooks
if [ -f "$GIT_ROOT/package.json" ]; then
  if node -e "process.exit(((require('$GIT_ROOT/package.json').scripts||{}).prepare)?0:1)" 2>/dev/null; then
    printf '%s· package.json already has a "prepare" script — make sure it includes:%s\n' "$YELLOW" "$NC"
    printf '    git config core.hooksPath .githooks\n'
  else
    say 'add "prepare": "git config core.hooksPath .githooks" to package.json'
    if [ "$DRY_RUN" != "1" ]; then
      node -e "
        const fs=require('fs'),p='$GIT_ROOT/package.json';
        const j=JSON.parse(fs.readFileSync(p,'utf8'));
        j.scripts=j.scripts||{};
        j.scripts.prepare='git config core.hooksPath .githooks';
        fs.writeFileSync(p,JSON.stringify(j,null,2)+'\n');
      " 2>/dev/null && \
        printf '%s✔ "prepare" script added to package.json (team inherits hooks on npm install)%s\n' "$GREEN" "$NC" || \
        printf '%s· Could not edit package.json — add manually: "prepare": "git config core.hooksPath .githooks"%s\n' "$YELLOW" "$NC"
    fi
  fi
fi

if [ "$DRY_RUN" = "1" ]; then
  printf '\n%s[dry-run]%s Nothing was written. Re-run without --dry-run to apply.\n' "$BLUE" "$NC"
  exit 0
fi

printf '\n%s✔ husky-skill installed.%s Active hooks: ' "$GREEN" "$NC"
for h in "$DEST"/*; do
  case "$h" in *.bak) continue ;; esac
  printf '%s ' "$(basename "$h")"
done
printf '\n  Try: git commit → pre-commit + commit-msg · git push → pre-push\n'
printf '  Emergency bypass: HUSKY=0 or --no-verify (CI is still the real gate)\n'
