# Publishing templates (subtrees)

This repo can publish each `templates/<name>/` folder to its own **template repository** using
- a GitHub Actions workflow: `.github/workflows/publish.yml`
- a local helper script: `scripts/publish-subtrees.sh`

Both are **parameterized** so you can change owner/branch/host without editing code.

---

## What gets published

> Keep this mapping in sync with `scripts/publish-subtrees.sh` and `.github/workflows/publish.yml`.

```
templates/fastapi     → ${PUBLISH_ORG}/template-fastapi
templates/flask       → ${PUBLISH_ORG}/template-flask
templates/flask-nginx → ${PUBLISH_ORG}/template-flask-nginx
templates/web         → ${PUBLISH_ORG}/template-web
templates/ds          → ${PUBLISH_ORG}/template-ds
templates/lib         → ${PUBLISH_ORG}/template-lib
templates/base        → ${PUBLISH_ORG}/template-base
```

Example (your account): `PUBLISH_ORG=fullcircle23`

---

## How it works (high level)

1. On push to `main` that touches `templates/**`, the **Publish templates** workflow runs.
2. For each template (matrix job), it:
   - splits history: `git subtree split --prefix=templates/<name>`
   - **force pushes** that split branch to the matching target repo (`<name>:main`).
3. Each matrix job loads **only** its deploy key (least-privilege).

> Force-push is required because `subtree split` rewrites history each run.

---

## One-time setup

### A) Create target template repos
Create these repos under your owner (e.g., `fullcircle23`) and mark them **Template repository** in GitHub settings:

```
template-fastapi, template-flask, template-flask-nginx,
template-web, template-ds, template-lib, template-base
```

### B) Add deploy keys (one per target repo)
For each target repo:
1. Generate an SSH keypair (no passphrase) just for that repo.
2. Add the **public key** to the target repo: **Settings → Deploy keys → Add deploy key** (+ **Allow write access**).
3. Add the **private key** to the **monorepo** as a secret (Settings → Secrets and variables → Actions), using these names:

```
DEPLOY_KEY_TEMPLATE_FASTAPI
DEPLOY_KEY_TEMPLATE_FLASK
DEPLOY_KEY_TEMPLATE_FLASK_NGINX
DEPLOY_KEY_TEMPLATE_WEB
DEPLOY_KEY_TEMPLATE_DS
DEPLOY_KEY_TEMPLATE_LIB
DEPLOY_KEY_TEMPLATE_BASE
```

> See `docs/DEPLOY_KEYS.md` for exact commands and a checklist.

### C) Configure owner/branch/host (no code edits)
Use **Repository variables** in the monorepo (Settings → Secrets and variables → Variables):

| Variable         | Controls                                | Default                           | Example        |
|------------------|------------------------------------------|-----------------------------------|----------------|
| `PUBLISH_ORG`    | Target owner of template repos           | `github.repository_owner`         | `fullcircle23` |
| `PUBLISH_BRANCH` | Branch to push to in target repos        | `main`                            | `main`         |
| `PUBLISH_HOST`   | Git host (supports GH Enterprise)        | `github.com`                      | `github.com`   |

CLI:
```bash
gh variable set PUBLISH_ORG -b "fullcircle23"
gh variable set PUBLISH_BRANCH -b "main"
gh variable set PUBLISH_HOST -b "github.com"
```

---

## Run it

### Automatic (CI)
- Push changes to `main` that affect `templates/**`.
- Or run manually from **Actions → Publish templates → Run workflow** (we enabled `workflow_dispatch`).

### Local (script)
You can publish from your machine (uses your SSH agent/keys):

```bash
# Dry-run preview
DRY_RUN=1 ./scripts/publish-subtrees.sh fullcircle23

# Real push (SSH)
./scripts/publish-subtrees.sh fullcircle23

# Alternate branch/host/protocol
BRANCH=main HOST=github.com PROTO=https ./scripts/publish-subtrees.sh fullcircle23
```

---

## Troubleshooting

### 1) “Permission denied (publickey)” or push fails
- Missing deploy key or **no write access** on the target repo.
- Check monorepo **secrets** exist and match the workflow matrix:
  - `DEPLOY_KEY_TEMPLATE_FASTAPI`, `DEPLOY_KEY_TEMPLATE_FLASK`, `DEPLOY_KEY_TEMPLATE_FLASK_NGINX`,
    `DEPLOY_KEY_TEMPLATE_WEB`, `DEPLOY_KEY_TEMPLATE_DS`, `DEPLOY_KEY_TEMPLATE_LIB`, `DEPLOY_KEY_TEMPLATE_BASE`
- Sanity checks:
  ```bash
  ssh -T git@github.com
  gh variable list | grep -E 'PUBLISH_(ORG|BRANCH|HOST)'
  gh secret list
  ```

### 2) Force push blocked
- Target repo has branch protection disallowing force-push.
- Fix: allow force pushes for `main`, **or** push to a staging branch then fast-forward `main` via a protected workflow in the target repo.

### 3) “Host key verification failed”
- Ensure `PUBLISH_HOST` is correct; the workflow runs `ssh-keyscan` to trust it.

### 4) “unknown revision or path” / nothing published
- Path is wrong or empty. Verify:
  ```bash
  git log --oneline -- templates/fastapi | head
  git ls-tree -r HEAD -- templates/fastapi | head
  ```
- Confirm mapping matches README, workflow, and script.

### 5) Wrong org/branch/host
- Use repo variables: `PUBLISH_ORG`, `PUBLISH_BRANCH`, `PUBLISH_HOST` (no code edits).

### 6) Wrong key loaded
- Each matrix job loads only its key via `secrets[matrix.key]`. Ensure secret names match.

### 7) SAML/SSO (orgs)
- Deploy keys are not subject to SSO; if you add user tokens, authorize them for the org.

### 8) Debug a failing publish step
Add temporary debug under the failing matrix item:
```yaml
- name: Debug env
  run: |
    echo ORG=${{ env.ORG }}
    echo BRANCH=${{ env.BRANCH }}
    echo HOST=${{ env.HOST }}
    git subtree split --prefix="templates/${{ matrix.src }}" -b dry-${{ matrix.src }}
    git log --oneline -n 3 dry-${{ matrix.src }}
    git branch -D dry-${{ matrix.src }}
```
You can also enable step debug logs by setting a repo secret `ACTIONS_STEP_DEBUG=true`.

### 9) Dry-run locally
```bash
DRY_RUN=1 ./scripts/publish-subtrees.sh fullcircle23
```

### 10) History or size concerns
- Subtree split is efficient, but if targets bloat, consider excluding large assets,
  pushing narrower subpaths, or squashing target repo history where appropriate.

---

## Security notes

- Use **deploy keys** (one per target repo) with **write** access; they are the least-privilege SSH credentials.
- Rotate keys periodically; remove stale keys from target repos and monorepo secrets.
- Avoid personal access tokens (PATs) unless you need Git operations beyond pushes.
- Keep `gitleaks` enabled in CI to prevent accidental secret leaks elsewhere.

---

## File index (for reference)

- `scripts/publish-subtrees.sh` — local publishing; parameterized via `ORG`, `BRANCH`, `HOST`, `PROTO`, `DRY_RUN`.
- `.github/workflows/publish.yml` — CI publishing; parameterized via `PUBLISH_*` variables; one job per template.
- `docs/DEPLOY_KEYS.md` — step-by-step deploy key setup.
