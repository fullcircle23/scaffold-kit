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

See **[docs/PUBLISHING.md](docs/PUBLISHING.md)** for configuration, mapping, and troubleshooting.

See **[docs/DEPLOY_KEYS.md](docs/DEPLOY_KEYS.md)** for deploy key setup.

## Versioning policy

- No version suffixes in repo names.
- Use Git **tags** (SemVer) and releases for versioning.
- Each template contains:
  - `TEMPLATE_VERSION` (human-readable)
  - `CHANGELOG.md` (Keep a Changelog)
  - `UPGRADE.md` (breaking-change notes & steps)

