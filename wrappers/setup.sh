#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./setup.sh <repo-name>
             [--profile base|web|ds|lib|fastapi|flask|flask-nginx]
             [--org <target-owner>] [--template-owner <owner>]
             [--public] [--no-push] [--ssh] [--ref <tag|branch|sha>]
EOF
}
if [[ $# -lt 1 ]]; then usage; exit 1; fi

REPO="$1"; shift || true
PROFILE="base"
ORG="${BOOTSTRAP_ORG:-}"
TEMPLATE_OWNER="${BOOTSTRAP_TEMPLATE_OWNER:-}"
VIS_FLAG="--private"
NO_PUSH=0
USE_SSH=0
BRANCH="${BOOTSTRAP_BRANCH:-main}"
REF=""

if [[ ! "$REPO" =~ ^[A-Za-z0-9._-]+$ ]]; then echo "[ERROR] Invalid repo name: $REPO"; exit 1; fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile) PROFILE="${2:-}"; shift 2 ;;
    --org) ORG="${2:-}"; shift 2 ;;
    --template-owner) TEMPLATE_OWNER="${2:-}"; shift 2 ;;
    --public) VIS_FLAG="--public"; shift ;;
    --no-push) NO_PUSH=1; shift ;;
    --ssh) USE_SSH=1; shift ;;
    --ref) REF="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "[ERROR] Unknown option: $1"; usage; exit 1 ;;
  esac
done

case "$PROFILE" in base|web|ds|lib|fastapi|flask|flask-nginx) ;; *)
  echo "[ERROR] Unknown profile: $PROFILE"; exit 1 ;;
esac

if [[ -e "$REPO" ]]; then echo "[ERROR] Target path '$REPO' already exists."; exit 1; fi
[[ -z "$TEMPLATE_OWNER" ]] && TEMPLATE_OWNER="$ORG"

template_url() {
  local owner="$1" prof="$2"
  if [[ $USE_SSH -eq 1 ]]; then
    echo "git@github.com:${owner}/template-${prof}.git"
  else
    echo "https://github.com/${owner}/template-${prof}.git"
  fi
}
remote_url() {
  local owner="$1" repo="$2"
  if [[ $USE_SSH -eq 1 ]]; then
    echo "git@github.com:${owner}/${repo}.git"
  else
    echo "https://github.com/${owner}/${repo}.git"
  fi
}

prefer_fallback=0; [[ -n "$REF" ]] && prefer_fallback=1
if command -v gh >/dev/null 2>&1 && [[ $prefer_fallback -eq 0 ]] && [[ -n "$TEMPLATE_OWNER" ]]; then
  create_arg="$REPO"; [[ -n "$ORG" ]] && create_arg="${ORG}/${REPO}"
  echo "[INFO] Using gh to create $create_arg from ${TEMPLATE_OWNER}/template-${PROFILE} ..."
  set +e; gh repo create "$create_arg" "$VIS_FLAG" --template "${TEMPLATE_OWNER}/template-${PROFILE}" --clone; status=$?; set -e
  if [[ $status -eq 0 ]]; then cd "$REPO"; echo "[OK] Bootstrapped via GitHub template."; exit 0
  else echo "[WARN] gh template create failed. Falling back."; fi
fi

if [[ -z "$TEMPLATE_OWNER" ]]; then echo "[ERROR] Fallback requires --template-owner or BOOTSTRAP_TEMPLATE_OWNER."; exit 1; fi

TPL_URL="$(template_url "$TEMPLATE_OWNER" "$PROFILE")"
echo "[INFO] Cloning template: $TPL_URL"
if [[ -n "$REF" ]]; then
  set +e; git clone --depth 1 --branch "$REF" "$TPL_URL" "$REPO"; status=$?; set -e
  if [[ $status -ne 0 ]]; then git clone "$TPL_URL" "$REPO"; cd "$REPO"; git checkout "$REF"; else cd "$REPO"; fi
else
  git clone "$TPL_URL" "$REPO"; cd "$REPO"
fi

rm -rf .git
if ! git init -b "$BRANCH" 2>/dev/null; then git init; git checkout -b "$BRANCH"; fi
git add .
git commit -m "chore: bootstrap from template-${PROFILE}${REF:+ @ $REF}"

if [[ $NO_PUSH -eq 0 ]]; then
  if command -v gh >/dev/null 2>&1; then
    target="$REPO"; [[ -n "$ORG" ]] && target="${ORG}/${REPO}"
    gh repo create "$target" "$VIS_FLAG" --source=. --push
  else
    if [[ -n "$ORG" ]]; then git remote add origin "$(remote_url "$ORG" "$REPO")"; git push -u origin "$BRANCH"
    else echo "[INFO] No gh and no --org; leaving repo local only."; fi
  fi
fi
echo "[OK] Bootstrapped $REPO from template-${PROFILE}${REF:+ @ $REF} on '$BRANCH'."
