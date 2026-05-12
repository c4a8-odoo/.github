#!/usr/bin/env bash

set -euo pipefail

# Determine which container runtime to use
if command -v podman >/dev/null 2>&1; then
  DOCKER_CMD="podman"
  echo "docker not found, using podman instead."
elif command -v docker >/dev/null 2>&1; then
  DOCKER_CMD="docker"
else
  echo "Error: neither docker nor podman is available." >&2
  exit 1
fi

usage() {
  cat <<'EOF'
Run the provided test.yml workflow test job locally on the current working tree.

Usage:
  bash skills/odoo-coding/scripts/run-odoo.sh [--db <database>] [--odoo-version <version>] [--python-version <version>]

Options:
  --db <database>        Override PGDATABASE (default: odoo).
  --odoo-version <ver>   Set Odoo version (default: 19.0).
  --python-version <ver> Set Python version (default: 3.10).
  -h, --help             Show this help.
EOF
}

PGDATABASE_VALUE="odoo"
ODOO_VERSION="19.0"
PYTHON_VERSION="3.10"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --db)
      PGDATABASE_VALUE="${2:-}"
      if [[ -z "$PGDATABASE_VALUE" ]]; then
        echo "Error: --db requires a value" >&2
        exit 1
      fi
      shift 2
      ;;
    --odoo-version)
      ODOO_VERSION="${2:-}"
      if [[ -z "$ODOO_VERSION" ]]; then
        echo "Error: --odoo-version requires a value" >&2
        exit 1
      fi
      shift 2
      ;;
    --python-version)
      PYTHON_VERSION="${2:-}"
      if [[ -z "$PYTHON_VERSION" ]]; then
        echo "Error: --python-version requires a value" >&2
        exit 1
      fi
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Error: unknown argument '$1'" >&2
      usage
      exit 1
      ;;
  esac
done



REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
NETWORK_NAME="oca-ci-test-net-$$"
PG_CONTAINER_NAME="oca-ci-postgres-$$"

cleanup() {
  $DOCKER_CMD rm -f "$PG_CONTAINER_NAME" >/dev/null 2>&1 || true
  $DOCKER_CMD network rm "$NETWORK_NAME" >/dev/null 2>&1 || true
}
trap cleanup EXIT


echo "Creating docker network: $NETWORK_NAME"
$DOCKER_CMD network create "$NETWORK_NAME"


echo "Starting postgres service container"
$DOCKER_CMD run -d --rm \
  --name "$PG_CONTAINER_NAME" \
  --network "$NETWORK_NAME" \
  -e POSTGRES_USER=odoo \
  -e POSTGRES_PASSWORD=odoo \
  -e POSTGRES_DB=odoo \
  postgres:13.0 >/dev/null

echo "Waiting for postgres to become ready"

for _ in $(seq 1 30); do
  if $DOCKER_CMD exec "$PG_CONTAINER_NAME" pg_isready -U odoo >/dev/null 2>&1; then
    break
  fi
  sleep 1
done


if ! $DOCKER_CMD exec "$PG_CONTAINER_NAME" pg_isready -U odoo >/dev/null 2>&1; then
  echo "Error: postgres did not become ready in time" >&2
  exit 1
fi

image="ghcr.io/oca/oca-ci/py${PYTHON_VERSION}-odoo${ODOO_VERSION}:latest"

echo ""
echo "=== Running local workflow in image: $image ==="
$DOCKER_CMD run --rm \
  --network "$NETWORK_NAME" \
  -p 8069:8069 \
  -v "$REPO_ROOT:/addon" \
  -e OCA_ENABLE_CHECKLOG_ODOO=1 \
  -e PGHOST="$PG_CONTAINER_NAME" \
  -e PGUSER=odoo \
  -e PGPASSWORD=odoo \
  -e PGDATABASE="$PGDATABASE_VALUE" \
  -e ADDONS_DIR=/addon \
  "$image" \
  /bin/bash -c "cd /addon && odoo --addons-path=/addon -i base --db-filter=^${PGDATABASE_VALUE}$"

echo ""
echo "Workflow replay finished successfully"
