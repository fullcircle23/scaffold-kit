#!/usr/bin/env bash
set -Eeuo pipefail

TEMPLATE="${1:-}"
if [[ -z "$TEMPLATE" ]]; then
  echo "Usage: $0 <template-name>"
  echo "Templates: base web ds lib fastapi flask flask-nginx"
  exit 1
fi

cd "templates/${TEMPLATE}"

py_upgrade() { python -m pip install --upgrade pip; }
py_lint()    { python -m ruff check .; python -m black --check .; }
py_test()    { python -m pytest -q; }

ensure_dotenv() {
  if [ -f .env.example ] && [ ! -f .env ]; then
    cp .env.example .env
  fi
}

node_install() {
  if [ -f package-lock.json ]; then
    npm ci
  else
    npm install --no-audit --no-fund
  fi
}

case "$TEMPLATE" in
  fastapi)
    py_upgrade
    pip install -r requirements.txt -r requirements-dev.txt
    ensure_dotenv
    py_lint
    py_test
    docker build -t ci-fastapi .
    docker compose config >/dev/null
    ;;
  flask)
    py_upgrade
    pip install -r requirements.txt -r requirements-dev.txt
    ensure_dotenv
    py_lint
    py_test
    docker build -t ci-flask .
    docker compose config >/dev/null
    ;;
  flask-nginx)
    py_upgrade
    pip install -r requirements.txt -r requirements-dev.txt
    ensure_dotenv
    py_lint
    py_test
    docker compose config >/dev/null
    ;;
  ds)
    py_upgrade
    pip install -r requirements-dev.txt   # skip heavy runtime deps for smoke tests
    py_lint
    py_test
    ;;
  web)
    node_install
    npm run lint
    npm run typecheck
    npm run build
    docker build -t ci-web .
    ;;
  lib)
    node_install
    npm run lint
    npm run typecheck
    npm run build
    npm test
    npm pack > /dev/null
    ;;
  base)
    test -f .editorconfig
    test -f .gitattributes
    test -f .gitignore
    test -f .github/CODEOWNERS
    test -f .github/SECURITY.md
    test -f .github/CONTRIBUTING.md
    test -f .github/ISSUE_TEMPLATE/bug_report.yml
    test -f .github/ISSUE_TEMPLATE/feature_request.yml
    ;;
  *)
    echo "Unknown template: $TEMPLATE"; exit 1;;
esac

echo "[OK] ${TEMPLATE} checks passed."
