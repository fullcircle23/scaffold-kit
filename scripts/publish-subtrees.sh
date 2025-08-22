#!/usr/bin/env bash
set -euo pipefail
ORG="${1:-${ORG:-fullcircle23}}"
BRANCH="${BRANCH:-main}"
HOST="${HOST:-github.com}"
PROTO="${PROTO:-ssh}"
DRY_RUN="${DRY_RUN:-0}"
MAP=("fastapi:template-fastapi" "flask:template-flask" "flask-nginx:template-flask-nginx" "web:template-web" "ds:template-ds" "lib:template-lib" "base:template-base")
remote_url(){ local target="$1"; if [[ "$PROTO" == "ssh" ]]; then echo "git@${HOST}:${ORG}/${target}.git"; else echo "https://${HOST}/${ORG}/${target}.git"; fi; }
push_subtree(){ local folder="$1" target="$2" tmp="pub-${folder//\//-}"; echo "==> Publishing templates/${folder} → ${ORG}/${target} (${BRANCH})"; git subtree split --prefix="templates/${folder}" -b "$tmp"; if [[ "$DRY_RUN" == "1" ]]; then echo "[DRY-RUN] git push -f $(remote_url "$target") $tmp:${BRANCH}"; else git push -f "$(remote_url "$target")" "$tmp:${BRANCH}"; fi; git branch -D "$tmp"; }
for pair in "${MAP[@]}"; do IFS=: read -r folder target <<<"$pair"; push_subtree "$folder" "$target"; done
echo "✓ Done."
