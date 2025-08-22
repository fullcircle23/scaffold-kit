#!/usr/bin/env bash
set -Eeuo pipefail

TEMPLATE="${1:-}"
if [[ -z "$TEMPLATE" ]]; then
  echo "Usage: $0 <template-name>"
  echo "Templates: base web ds lib fastapi flask flask-nginx"
  exit 1
fi

cd "templates/${TEMPLATE}"

run_python() {
  python -m pip install --upgrade pip
  pip install -r requirements.txt -r requirements-dev.txt
  ruff check .
  black --check .
  pytest -q
}

run_node_web() {
  npm ci
  npm run lint
  npm run typecheck
  npm run build
}

run_node_lib() {
  npm ci
  npm run lint
  npm run typecheck
  npm test
  npm pack > /dev/null
}

case "$TEMPLATE" in
  fastapi)
    run_python
    docker build -t ci-fastapi .
    docker compose config >/dev/null
    ;;
  flask)
    run_python
    docker build -t ci-flask .
    docker compose config >/dev/null
    ;;
  flask-nginx)
    # Flask app uses gunicorn; compose includes nginx
    python -m pip install --upgrade pip
    pip install -r requirements.txt -r requirements-dev.txt
    ruff check .
    black --check .
    pytest -q
    docker compose config >/dev/null
    ;;
  ds)
    run_python
    ;;
  web)
    run_node_web
    docker build -t ci-web .
    ;;
  lib)
    run_node_lib
    ;;
  base)
    # meta checks
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
