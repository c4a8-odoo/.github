#!/usr/bin/env bash

set -euo pipefail

# Check for docker or podman and alias if needed
if ! command -v docker >/dev/null 2>&1; then
  if command -v podman >/dev/null 2>&1; then
    mkdir -p /tmp/docker-shim 
    printf '#!/bin/bash\nexec podman "$@"\n' > /tmp/docker-shim/docker 
    chmod +x /tmp/docker-shim/docker 
    echo "Shim created"
  fi
fi

usage() {
  cat <<'EOF'
Run the provided test.yml workflow test job locally on the current working tree.

Usage:
  bash skills/odoo-tests/scripts/run-test-workflow.sh [--with-ocb] [--include <module>] [--db <database>] [--odoo-version <version>] [--python-version <version>]

Options:
  --with-ocb             Run both matrix images (Odoo first, then OCB).
  --include <module>     Restrict test selection via INCLUDE.
  --db <database>        Override PGDATABASE (default: odoo).
  --odoo-version <ver>   Set Odoo version (default: 19.0).
  --python-version <ver> Set Python version (default: 3.10).
  -h, --help             Show this help.
EOF
}

WITH_OCB=0
INCLUDE_VALUE=""
PGDATABASE_VALUE="odoo"
ODOO_VERSION="19.0"
PYTHON_VERSION="3.10"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --with-ocb)
      WITH_OCB=1
      shift
      ;;
    --include)
      INCLUDE_VALUE="${2:-}"
      if [[ -z "$INCLUDE_VALUE" ]]; then
        echo "Error: --include requires a value" >&2
        exit 1
      fi
      shift 2
      ;;
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

if ! command -v docker >/dev/null 2>&1; then
  echo "Error: docker is required" >&2
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
NETWORK_NAME="oca-ci-test-net-$$"
PG_CONTAINER_NAME="oca-ci-postgres-$$"

cleanup() {
  docker rm -f "$PG_CONTAINER_NAME" >/dev/null 2>&1 || true
  docker network rm "$NETWORK_NAME" >/dev/null 2>&1 || true
}
trap cleanup EXIT

echo "Creating docker network: $NETWORK_NAME"
docker network create "$NETWORK_NAME" >/dev/null

echo "Starting postgres service container"
docker run -d --rm \
  --name "$PG_CONTAINER_NAME" \
  --network "$NETWORK_NAME" \
  -e POSTGRES_USER=odoo \
  -e POSTGRES_PASSWORD=odoo \
  -e POSTGRES_DB=odoo \
  postgres:13.0 >/dev/null

echo "Waiting for postgres to become ready"
for _ in $(seq 1 30); do
  if docker exec "$PG_CONTAINER_NAME" pg_isready -U odoo >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

if ! docker exec "$PG_CONTAINER_NAME" pg_isready -U odoo >/dev/null 2>&1; then
  echo "Error: postgres did not become ready in time" >&2
  exit 1
fi

IMAGES=("ghcr.io/oca/oca-ci/py${PYTHON_VERSION}-odoo${ODOO_VERSION}:latest")
if [[ "$WITH_OCB" -eq 1 ]]; then
  IMAGES+=("ghcr.io/oca/oca-ci/py${PYTHON_VERSION}-ocb${ODOO_VERSION}:latest")
fi

for image in "${IMAGES[@]}"; do
  echo ""
  echo "=== Running local workflow in image: $image ==="
  docker run --rm \
    --network "$NETWORK_NAME" \
    -v "$REPO_ROOT:/addon" \
    -e OCA_ENABLE_CHECKLOG_ODOO=1 \
    -e PGHOST="$PG_CONTAINER_NAME" \
    -e PGUSER=odoo \
    -e PGPASSWORD=odoo \
    -e PGDATABASE="$PGDATABASE_VALUE" \
    -e ADDONS_DIR=/addon \
    -e INCLUDE="$INCLUDE_VALUE" \
    -e EXCLUDE="" \
    "$image" \
    bash -lc '
      set -euo pipefail
      dropdb --if-exists "$PGDATABASE" || true
      # disable log output to avoid ai flooding
      oca_install_addons > /dev/null
      oca_init_test_database  > /dev/null
      oca_run_tests
    '
done

echo ""
echo "Workflow replay finished successfully"
