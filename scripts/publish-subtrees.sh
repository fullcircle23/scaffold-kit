#!/usr/bin/env bash
set -euo pipefail
# Usage: GIT_SSH_COMMAND='ssh -i /path/to/key' ./scripts/publish-subtrees.sh your-org
ORG="${1:-your-org}"
function push_subtree() {
  local folder="$1" target="$2"
  local branch="pub-${folder//\//-}"
  git subtree split --prefix="templates/${folder}" -b "$branch"
  git push -f "git@github.com:${ORG}/${target}.git" "$branch:main"
  git branch -D "$branch"
}
push_subtree base          template-base
push_subtree web           template-web
push_subtree ds            template-ds
push_subtree lib           template-lib
push_subtree fastapi       template-fastapi
push_subtree flask         template-flask
push_subtree flask-nginx   template-flask-nginx
