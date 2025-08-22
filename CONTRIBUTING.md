# Contributing to scaffold-kit

Thanks for helping improve our repo templates and wrappers! This monorepo is the **source of truth** for all templates and the wrapper scripts.

## Scope
- `templates/*`: production-ready templates (FastAPI, Flask, Flask+Nginx, Vite+TS, DS, Node TS lib, Base)
- `wrappers/`: setup scripts (`setup.sh`, `setup.bat`)
- `.github/workflows/publish.yml`: publishes subfolders to separate GitHub **template** repos via `git subtree`

## Branching & releases
- Default branch: **main** (protected).
- Use **Conventional Commits** (`feat:`, `fix:`, `docs:`, `chore:`, `refactor:` …).
- Version **per template** via SemVer tags on their target repos; tag the monorepo as well to track a coherent release of all templates.
- Update each template’s `TEMPLATE_VERSION`, `CHANGELOG.md`, and `UPGRADE.md` when you change it.

## Making changes (quick checklist)
1. Pick a template folder under `templates/` and make your changes.
2. Update docs in that template:
   - `CHANGELOG.md`: add an entry.
   - `UPGRADE.md`: record any breaking changes with migration steps.
   - `TEMPLATE_VERSION`: bump version (e.g., `2.0.1`).
3. Verify locally:
   - **FastAPI**: `make install && make lint && make test && docker compose up --build`
   - **Flask**: `make install && make lint && make test && docker compose up --build`
   - **Flask+Nginx**: `docker compose up --build` (app on port 8080)
   - **Web (Vite+TS)**: `npm ci && npm run lint && npm run typecheck && npm run build`
   - **DS**: `make install && make lint && make test`
   - **Lib (Node TS)**: `npm ci && npm run lint && npm run typecheck && npm test`
4. Open a PR:
   - Describe the change & motivation; include screenshots/logs where useful.
   - Mention templates affected and whether it’s breaking.
   - Ensure CI is green.

## Publishing
Publishing to `{org}/template-*` repos happens via:
- **GitHub Actions**: `.github/workflows/publish.yml` triggers on changes under `templates/**` (recommended).
- **Local**: `scripts/publish-subtrees.sh your-org` (requires your local SSH to have write access).

> Before publishing the first time, set up **Deploy Keys** and GitHub **secrets**. See `docs/DEPLOY_KEYS.md`.

## Code style
- Python: Black + Ruff (configured per template).
- Node/TS: ESLint + Prettier (configured per template).
- Shell: POSIX sh/bash, `set -Eeuo pipefail` in scripts.

## Security
- Do not commit real secrets. Use `.env.example` and GitHub Secrets.
- Only use trusted base Docker images and pin versions where practical.
