# husky-skill

Git hooks estilo Husky, **sin dependencias npm**. Pre-commit, commit-msg y
pre-push en POSIX shell puro — pensado para equipos con políticas estrictas
de dependencias (fintech, entornos regulados) que no pueden instalar Husky
pero necesitan todo lo que Husky hace.

## Instalación

### Como agent skill (skills.sh)

```sh
npx skills add KloutDevs/husky-skill
```

Después pedile a tu agente: *"instalá los git hooks en este repo"*.

### Manual (cualquier repo, sin agentes)

```sh
git clone https://github.com/KloutDevs/husky-skill
cd tu-proyecto
sh ../husky-skill/scripts/install.sh
```

Eso copia los hooks a `.githooks/`, configura `core.hooksPath` y agrega un
script `prepare` a tu `package.json` para que todo el equipo herede los
hooks con `npm install`.

## Qué incluye

| Hook | Checks | Tiempo |
|---|---|---|
| `pre-commit` | Secret scan · .env/llaves bloqueadas · archivos >5MB · conflict markers · Prettier · ESLint | <5s |
| `commit-msg` | Conventional Commits (`feat(scope): ...`), ≤72 chars, sin commitlint | instantáneo |
| `pre-push` | `tsc --noEmit` completo · `npm run build` · `npm test` | 30s–2min |

## Filosofía

- **Un hook lento es un hook bypasseado.** Lo rápido va en pre-commit, lo
  pesado en pre-push. Nada roto sale de tu máquina; nada te hace odiar
  commitear.
- **El hook nunca modifica tus archivos.** Sin `--fix` automático: si un
  archivo tiene cambios staged y no-staged, un auto-fix commitearía código
  que no revisaste.
- **Cero egress.** Se usa `node_modules/.bin/`, nunca `npx` (que puede
  descargar de la red). Un hook solo corre lo ya instalado y auditado.
- **Los hooks son filtro, no seguridad.** `--no-verify` existe. CI es el
  gate obligatorio; esto es feedback temprano.

## Escape hatches

```sh
SKIP_ESLINT=1 / SKIP_PRETTIER=1     # en commit
SKIP_TYPESCRIPT=1 / SKIP_BUILD=1 / SKIP_TESTS=1   # en push
HUSKY=0 git commit                  # todo apagado (CI/emergencias)
git commit --no-verify              # bypass nativo de git
```

El secret scan **no tiene skip**: una credencial commiteada es un
incidente, no una preferencia.

## Personalizar por proyecto

Los hooks instalados viven en `.githooks/` de *tu* repo — shell plano,
versionado, revisable en PR. Editalos ahí. Ejemplo: si tu equipo solo
aprueba ESLint + Prettier, borrá las secciones de build/tests de
`pre-push` y listo.

## Requisitos

Git ≥2.9 y `sh`. Node/ESLint/Prettier/TypeScript se detectan y usan solo
si existen.

## Licencia

MIT
