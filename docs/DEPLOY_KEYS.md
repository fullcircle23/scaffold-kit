# Deploy Keys & Secrets for Publishing Templates

This repository publishes `templates/<name>` into **separate GitHub template repos** using `git subtree`.
We recommend **per-repo Deploy Keys** (SSH) for least privilege.

## Option A (Recommended): Deploy Keys per target repo

Repeat for each target repo (e.g., `template-fastapi`, `template-flask`, …).

### 1) Generate an SSH keypair
On your machine:
```bash
ssh-keygen -t ed25519 -C "deploy key for template-fastapi" -f ./id_ed25519_template_fastapi -N ""
```

- **Private key**: `id_ed25519_template_fastapi`
- **Public key**:  `id_ed25519_template_fastapi.pub`

### 2) Add the **public key** to the target repo
On GitHub → target repo **Settings → Deploy keys → Add deploy key**:
- Title: `scaffold-kit publish`
- Key: paste content of `id_ed25519_template_fastapi.pub`
- ✅ Check **Allow write access**

### 3) Add the **private key** as a secret to the monorepo
On GitHub → your **scaffold-kit** repo → **Settings → Secrets and variables → Actions → New repository secret**:
- Name: `DEPLOY_KEY_TEMPLATE_FASTAPI`
- Value: paste content of `id_ed25519_template_fastapi`

Repeat for all templates (FLASK, FLASK_NGINX, WEB, DS, LIB, BASE).

### 4) Known hosts
The workflow will add GitHub’s host key via `ssh-keyscan`, so no interactive prompts block pushes.

### 5) Configure git identity
The workflow sets a bot identity so the pushed commits have a friendly author.

## Option B: Machine user (service account) PAT
Create a machine-user GitHub account, grant it write access on all template repos, store its **SSH key** or **PAT** in a single secret, and use it instead of per-repo deploy keys. This is simpler to maintain but has broader access than strictly necessary.

## Workflow reference

This repo includes `.github/workflows/publish.yml`. It:
- Checks out with full history
- Starts an SSH agent with your deploy keys
- Adds `github.com` to `known_hosts`
- Publishes each subtree to its corresponding target repo

Secrets referenced (you create them in step 3 above):
- `DEPLOY_KEY_TEMPLATE_FASTAPI`
- `DEPLOY_KEY_TEMPLATE_FLASK`
- `DEPLOY_KEY_TEMPLATE_FLASK_NGINX`
- `DEPLOY_KEY_TEMPLATE_WEB`
- `DEPLOY_KEY_TEMPLATE_DS`
- `DEPLOY_KEY_TEMPLATE_LIB`
- `DEPLOY_KEY_TEMPLATE_BASE`

If you use different secret names, update the workflow accordingly.

## Pre-flight checklist
- [ ] All target repos exist and are marked as **Template repository**
- [ ] Deploy keys added to each target repo with **write** access
- [ ] Matching private keys added as **secrets** to this monorepo
- [ ] Branch protection enabled on `main` for target repos (optional)
- [ ] A maintainer verified a dry run locally with `scripts/publish-subtrees.sh`
