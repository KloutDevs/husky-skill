#!/bin/sh
# husky-skill · install.sh
# Instala los hooks en el repo Git actual. Idempotente: correrlo dos veces
# no rompe nada. Cero dependencias: solo git + sh.
#
# Uso:
#   sh scripts/install.sh            # desde el repo de husky-skill
#   sh path/to/install.sh            # desde cualquier repo destino
#
# Qué hace:
#   1. Verifica que estás dentro de un repo Git
#   2. Copia assets/hooks/* → .githooks/ del repo destino
#   3. git config core.hooksPath .githooks
#   4. Asegura permisos de ejecución
#   5. (opcional) agrega "prepare" a package.json si existe y no hay uno

set -e

SKILL_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
HOOKS_SRC="$SKILL_DIR/assets/hooks"

if [ -t 1 ]; then
  GREEN=$(printf '\033[0;32m'); YELLOW=$(printf '\033[0;33m')
  RED=$(printf '\033[0;31m'); NC=$(printf '\033[0m')
else
  GREEN=''; YELLOW=''; RED=''; NC=''
fi

# 1. ¿Estamos en un repo Git?
if ! GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null); then
  printf '%s✖ No estás dentro de un repositorio Git.%s\n' "$RED" "$NC" >&2
  printf '  Corré esto desde la raíz del proyecto donde querés los hooks.\n' >&2
  exit 1
fi

if [ ! -d "$HOOKS_SRC" ]; then
  printf '%s✖ No encuentro %s%s\n' "$RED" "$HOOKS_SRC" "$NC" >&2
  exit 1
fi

DEST="$GIT_ROOT/.githooks"
mkdir -p "$DEST"

# 2. Copiar hooks (con backup si el destino difiere)
for hook in "$HOOKS_SRC"/*; do
  name=$(basename "$hook")
  target="$DEST/$name"
  if [ -f "$target" ] && ! cmp -s "$hook" "$target"; then
    cp "$target" "$target.bak"
    printf '%s· %s existente difiere → backup en %s.bak%s\n' "$YELLOW" "$name" "$name" "$NC"
  fi
  cp "$hook" "$target"
  chmod +x "$target"
done

# 3. Apuntar Git a la carpeta (idempotente)
CURRENT=$(git -C "$GIT_ROOT" config --local core.hooksPath 2>/dev/null || true)
if [ "$CURRENT" != ".githooks" ]; then
  git -C "$GIT_ROOT" config core.hooksPath .githooks
  printf '%s✔ core.hooksPath → .githooks%s\n' "$GREEN" "$NC"
else
  printf '%s· core.hooksPath ya estaba configurado%s\n' "$YELLOW" "$NC"
fi

# 4. Sugerir/agregar prepare script para que el equipo lo herede
if [ -f "$GIT_ROOT/package.json" ]; then
  if node -e "process.exit(((require('$GIT_ROOT/package.json').scripts||{}).prepare)?0:1)" 2>/dev/null; then
    printf '%s· package.json ya tiene un script "prepare" — verificá que incluya:%s\n' "$YELLOW" "$NC"
    printf '    git config core.hooksPath .githooks\n'
  else
    node -e "
      const fs=require('fs'),p='$GIT_ROOT/package.json';
      const j=JSON.parse(fs.readFileSync(p,'utf8'));
      j.scripts=j.scripts||{};
      j.scripts.prepare='git config core.hooksPath .githooks';
      fs.writeFileSync(p,JSON.stringify(j,null,2)+'\n');
    " 2>/dev/null && \
      printf '%s✔ Script "prepare" agregado a package.json (el equipo hereda los hooks con npm install)%s\n' "$GREEN" "$NC" || \
      printf '%s· No pude editar package.json — agregá a mano: "prepare": "git config core.hooksPath .githooks"%s\n' "$YELLOW" "$NC"
  fi
fi

printf '\n%s✔ husky-skill instalado.%s Hooks activos: ' "$GREEN" "$NC"
ls "$DEST" | grep -v '\.bak$' | tr '\n' ' '
printf '\n  Probá: git commit → pre-commit + commit-msg · git push → pre-push\n'
printf '  Bypass de emergencia: HUSKY=0 o --no-verify (CI sigue siendo el gate real)\n'
