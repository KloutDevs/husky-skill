#!/bin/sh
# husky-skill · install.sh
# Installs the hooks into the current Git repo. Idempotent: running it twice
# breaks nothing. Zero dependencies: just git + sh.
#
# Usage:
#   sh scripts/install.sh            # from the husky-skill repo
#   sh path/to/install.sh            # from any target repo
#
# What it does:
#   1. Verifies you are inside a Git repo
#   2. Copies assets/hooks/* → .githooks/ in the target repo
#   3. git config core.hooksPath .githooks
#   4. Ensures execute permissions
#   5. (optional) adds a "prepare" script to package.json if present and absent

set -e

SKILL_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
HOOKS_SRC="$SKILL_DIR/assets/hooks"

if [ -t 1 ]; then
  GREEN=$(printf '\033[0;32m'); YELLOW=$(printf '\033[0;33m')
  RED=$(printf '\033[0;31m'); NC=$(printf '\033[0m')
else
  GREEN=''; YELLOW=''; RED=''; NC=''
fi

# 1. Are we inside a Git repo?
if ! GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null); then
  printf '%s✖ You are not inside a Git repository.%s\n' "$RED" "$NC" >&2
  printf '  Run this from the root of the project where you want the hooks.\n' >&2
  exit 1
fi

if [ ! -d "$HOOKS_SRC" ]; then
  printf '%s✖ Cannot find %s%s\n' "$RED" "$HOOKS_SRC" "$NC" >&2
  exit 1
fi

DEST="$GIT_ROOT/.githooks"
mkdir -p "$DEST"

# 2. Copy hooks (with backup if the destination differs)
for hook in "$HOOKS_SRC"/*; do
  name=$(basename "$hook")
  target="$DEST/$name"
  if [ -f "$target" ] && ! cmp -s "$hook" "$target"; then
    cp "$target" "$target.bak"
    printf '%s· existing %s differs → backed up to %s.bak%s\n' "$YELLOW" "$name" "$name" "$NC"
  fi
  cp "$hook" "$target"
  chmod +x "$target"
done

# 3. Point Git at the folder (idempotent)
CURRENT=$(git -C "$GIT_ROOT" config --local core.hooksPath 2>/dev/null || true)
if [ "$CURRENT" != ".githooks" ]; then
  git -C "$GIT_ROOT" config core.hooksPath .githooks
  printf '%s✔ core.hooksPath → .githooks%s\n' "$GREEN" "$NC"
else
  printf '%s· core.hooksPath was already configured%s\n' "$YELLOW" "$NC"
fi

# 4. Suggest/add a prepare script so the team inherits the hooks
if [ -f "$GIT_ROOT/package.json" ]; then
  if node -e "process.exit(((require('$GIT_ROOT/package.json').scripts||{}).prepare)?0:1)" 2>/dev/null; then
    printf '%s· package.json already has a "prepare" script — make sure it includes:%s\n' "$YELLOW" "$NC"
    printf '    git config core.hooksPath .githooks\n'
  else
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

printf '\n%s✔ husky-skill installed.%s Active hooks: ' "$GREEN" "$NC"
ls "$DEST" | grep -v '\.bak$' | tr '\n' ' '
printf '\n  Try: git commit → pre-commit + commit-msg · git push → pre-push\n'
printf '  Emergency bypass: HUSKY=0 or --no-verify (CI is still the real gate)\n'
