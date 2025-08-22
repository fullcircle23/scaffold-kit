> See also: [Publishing guide](PUBLISHING.md) · [Back to README](../README.md)

# Deploy keys for template publishing

This guide walks you through creating **one SSH deploy key _per template repo_**, granting it **write** access on the
target repo, and storing the **private key** as an **Actions secret** in this monorepo so the `Publish templates`
workflow can push subtrees.

Deploy keys are least-privilege SSH keys tied to a single repo (not a user).

---

## Prerequisites

1. Create the target template repositories under your owner (e.g., `fullcircle23`) and mark each as a **Template repository**.
   ```text
   template-fastapi, template-flask, template-flask-nginx,
   template-web, template-ds, template-lib, template-base
   ```
2. In this monorepo, configure (optional) **Repository variables** to avoid code edits:
   - `PUBLISH_ORG` (e.g., `fullcircle23`)
   - `PUBLISH_BRANCH` (default `main`)
   - `PUBLISH_HOST` (default `github.com`)

---

## 1) Generate a unique deploy key for each target repo

> macOS/Linux (or Windows Git Bash/WSL). Use **ed25519** and **no passphrase** for CI use.

```bash
# FastAPI
ssh-keygen -t ed25519 -C "deploy: template-fastapi" -f ~/.ssh/template-fastapi_deploy -N ""
# Flask
ssh-keygen -t ed25519 -C "deploy: template-flask" -f ~/.ssh/template-flask_deploy -N ""
# Flask + Nginx
ssh-keygen -t ed25519 -C "deploy: template-flask-nginx" -f ~/.ssh/template-flask-nginx_deploy -N ""
# Web
ssh-keygen -t ed25519 -C "deploy: template-web" -f ~/.ssh/template-web_deploy -N ""
# DS
ssh-keygen -t ed25519 -C "deploy: template-ds" -f ~/.ssh/template-ds_deploy -N ""
# Lib
ssh-keygen -t ed25519 -C "deploy: template-lib" -f ~/.ssh/template-lib_deploy -N ""
# Base
ssh-keygen -t ed25519 -C "deploy: template-base" -f ~/.ssh/template-base_deploy -N ""
```

Show the public keys (copy these to the target repos):
```bash
for f in ~/.ssh/*_deploy.pub; do echo "==> $f"; cat "$f"; echo; done
```

---

## 2) Add the **public key** to each target repo (Allow write access)

You can use the GitHub UI or GitHub CLI.

### UI
Target repo → **Settings → Deploy keys → Add deploy key**
- Title: matches repo (e.g., `deploy: template-fastapi`)
- Key: paste contents of `~/.ssh/template-fastapi_deploy.pub`
- ✅ **Allow write access**

Repeat for all template repos.

### CLI
```bash
# Replace OWNER with your account/org (e.g., fullcircle23)
OWNER="fullcircle23"
gh repo deploy-key add "$OWNER/template-fastapi"     ~/.ssh/template-fastapi_deploy.pub     --allow-write
gh repo deploy-key add "$OWNER/template-flask"       ~/.ssh/template-flask_deploy.pub       --allow-write
gh repo deploy-key add "$OWNER/template-flask-nginx" ~/.ssh/template-flask-nginx_deploy.pub --allow-write
gh repo deploy-key add "$OWNER/template-web"         ~/.ssh/template-web_deploy.pub         --allow-write
gh repo deploy-key add "$OWNER/template-ds"          ~/.ssh/template-ds_deploy.pub          --allow-write
gh repo deploy-key add "$OWNER/template-lib"         ~/.ssh/template-lib_deploy.pub         --allow-write
gh repo deploy-key add "$OWNER/template-base"        ~/.ssh/template-base_deploy.pub        --allow-write
```

---

## 3) Add the **private key** to this monorepo as Actions **secrets**

Create these secrets (names must match the workflow matrix keys):

| Secret name                       | Private key file                        |
|----------------------------------|-----------------------------------------|
| `DEPLOY_KEY_TEMPLATE_FASTAPI`    | `~/.ssh/template-fastapi_deploy`        |
| `DEPLOY_KEY_TEMPLATE_FLASK`      | `~/.ssh/template-flask_deploy`          |
| `DEPLOY_KEY_TEMPLATE_FLASK_NGINX`| `~/.ssh/template-flask-nginx_deploy`    |
| `DEPLOY_KEY_TEMPLATE_WEB`        | `~/.ssh/template-web_deploy`            |
| `DEPLOY_KEY_TEMPLATE_DS`         | `~/.ssh/template-ds_deploy`             |
| `DEPLOY_KEY_TEMPLATE_LIB`        | `~/.ssh/template-lib_deploy`            |
| `DEPLOY_KEY_TEMPLATE_BASE`       | `~/.ssh/template-base_deploy`           |

### UI
Monorepo → **Settings → Secrets and variables → Actions → New repository secret**  
Name one of the above, then paste the **entire contents** of the corresponding private key file.

### CLI
```bash
# Example for FastAPI; repeat per secret/file
gh secret set DEPLOY_KEY_TEMPLATE_FASTAPI < ~/.ssh/template-fastapi_deploy
```

> ⚠️ Make sure you paste the **private key** (no `.pub`) and preserve line breaks. On Windows, avoid CRLF conversions.

---

## 4) Verify

- In **Actions → Publish templates**, click **Run workflow** (uses `workflow_dispatch`) or push to `main` touching `templates/**`.
- Each matrix job should push to its own target repo.
- If force-push is blocked by branch protection in a target repo, allow it or push to a staging branch and fast‑forward via a protected workflow there.

---

## 5) Rotate a deploy key

1. Add a **new** deploy key (public) to the target repo, keep the old one for now.
2. Update the **monorepo secret** with the **new private key**.
3. Run the publish workflow to verify.
4. Remove the **old** deploy key from the target repo and (optionally) delete the old secret from the monorepo.

---

## Troubleshooting

### “Permission denied (publickey)”
- Missing deploy key on target repo or **write** box not ticked.
- Wrong secret name or wrong private key pasted.
- Host key verification: the workflow runs `ssh-keyscan` automatically; confirm `PUBLISH_HOST` matches your host.

### “Updates were rejected because the remote contains work…”
- Publish uses `git push -f` (force). Allow force push on the target repo’s branch, or switch to a staging branch + fast‑forward pattern.

### “unknown revision or path not in the working tree”
- The template folder path is wrong or empty. Verify:
  ```bash
  git log --oneline -- templates/fastapi | head
  git ls-tree -r HEAD -- templates/fastapi | head
  ```

### Dry‑run locally (no pushes)
```bash
DRY_RUN=1 ./scripts/publish-subtrees.sh fullcircle23
```

---

## Security notes

- Use **one key per target repo**; don’t reuse across repos.
- Store only **private keys** in monorepo **secrets**. Public keys live only on target repos.
- Prefer SSH deploy keys over PATs for Git pushes in CI.
- Rotate keys periodically and remove stale keys from targets and secrets.
