# scaffold-kit

A curated set of production-ready **repo templates** (FastAPI, Flask, Flask+Nginx, Vite+TS, DS, Node TS lib, Base),
plus **wrapper scripts** and a **publish** workflow to push each template to its own GitHub template repository.

- **Date**: 2025-08-22
- **Templates**: base, web, ds, lib, fastapi, flask, flask-nginx
- **Wrappers**: `wrappers/setup.sh` (macOS/Linux), `wrappers/setup.bat` (Windows)

## Using the wrappers

Create a repo from a template (unsuffixed names) under your org:
```bash
./wrappers/setup.sh my-api --profile fastapi --org your-org --template-owner your-org
```

### Pinning a specific template version with `--ref`
Pass a **tag/branch/SHA** via `--ref` to pin the snapshot:
```bash
./wrappers/setup.sh my-api --profile fastapi --org your-org --template-owner your-org --ref v2.0.1
```
> `--ref` is honored in the fallback clone path so you get the **exact** tag/branch/SHA before we re-init the new repo.

Windows:
```bat
wrappers\setup.bat my-api --profile fastapi --org your-org --template-owner your-org --ref v2.0.1
```

## Publishing subfolders to template repos

### Configure publishing (no code edits)

The publish workflow and script are parameterized via **Repository variables** (Settings → Secrets and variables → Variables):

| Variable          | What it controls                            | Default if unset                    | Example        |
|-------------------|----------------------------------------------|-------------------------------------|----------------|
| `PUBLISH_ORG`     | Target owner (user/org) of template repos    | `github.repository_owner`           | `fullcircle23` |
| `PUBLISH_BRANCH`  | Branch to push in target repos               | `main`                              | `main`         |
| `PUBLISH_HOST`    | Git host (supports GH Enterprise)            | `github.com`                        | `github.com`   |

You can also set these via CLI:
```bash
gh variable set PUBLISH_ORG -b "fullcircle23"
gh variable set PUBLISH_BRANCH -b "main"
gh variable set PUBLISH_HOST -b "github.com"
```

Make sure the deploy key **secrets** exist (Settings → Secrets and variables → Actions):
- `DEPLOY_KEY_TEMPLATE_FASTAPI`
- `DEPLOY_KEY_TEMPLATE_FLASK`
- `DEPLOY_KEY_TEMPLATE_FLASK_NGINX`
- `DEPLOY_KEY_TEMPLATE_WEB`
- `DEPLOY_KEY_TEMPLATE_DS`
- `DEPLOY_KEY_TEMPLATE_LIB`
- `DEPLOY_KEY_TEMPLATE_BASE`

> Mapping (keep in sync with `scripts/publish-subtrees.sh` and `.github/workflows/publish.yml`):
>
```
templates/fastapi     → ${PUBLISH_ORG}/template-fastapi
templates/flask       → ${PUBLISH_ORG}/template-flask
templates/flask-nginx → ${PUBLISH_ORG}/template-flask-nginx
templates/web         → ${PUBLISH_ORG}/template-web
templates/ds          → ${PUBLISH_ORG}/template-ds
templates/lib         → ${PUBLISH_ORG}/template-lib
templates/base        → ${PUBLISH_ORG}/template-base
```

This repo includes a workflow (`.github/workflows/publish.yml`) and a helper script (`scripts/publish-subtrees.sh`)
that push each `templates/<name>` folder to its own repository:
- `templates/fastapi     → ${PUBLISH_ORG}/template-fastapi`
- `templates/flask       → ${PUBLISH_ORG}/template-flask`
- `templates/flask-nginx → ${PUBLISH_ORG}/template-flask-nginx`
- `templates/web         → ${PUBLISH_ORG}/template-web`
- `templates/ds          → ${PUBLISH_ORG}/template-ds`
- `templates/lib         → ${PUBLISH_ORG}/template-lib`
- `templates/base        → ${PUBLISH_ORG}/template-base`

Mark each target repo once as a **Template repository** in GitHub settings. The workflow uses `git subtree split`.

## Versioning policy

- No version suffixes in repo names.
- Use Git **tags** (SemVer) and releases for versioning.
- Each template contains:
  - `TEMPLATE_VERSION` (human-readable)
  - `CHANGELOG.md` (Keep a Changelog)
  - `UPGRADE.md` (breaking-change notes & steps)

