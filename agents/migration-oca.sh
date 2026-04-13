#!/bin/bash
# This is a migration script for one module
# Usage: ./migration-oca.sh [old_version] [new_version] [user_org] [source_path] [module] [source_branch] [target_branch]
# Authenticate first with: gh auth login

set -euo pipefail

version_old="${1:-18.0}"
version="${2:-19.0}"
user_org="${3:-origin}"
source_path="${4:-/src/user/modules/oca/crm}"
module_name="${5:-}"
source_branch="${6:-$version_old}"
target_branch="${7:-$version}"

LOG_FILE="${LOG_FILE:-/tmp/migration.log}"

log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

main() {
  if [ -z "$module_name" ]; then
    echo "ERROR: module parameter is required"; exit 1
  fi

  log "=== Migration Start ==="
  log "Version: $version_old -> $version"
  log "Branch: $source_branch -> $target_branch"
  log "Source: $source_path"
  log "Module: $module_name"
  log "Remote: $user_org"

  cd "$source_path" || { log "[ERROR] Cannot cd to $source_path"; return 1; }

  log "[PATCH] Applying format-patch from $user_org/$target_branch..$user_org/$source_branch"
  if git format-patch --keep-subject --stdout "$user_org/$target_branch".."$user_org/$source_branch" -- "$module_name" 2>/dev/null | git am -3 --keep 2>/dev/null; then
    log "[PATCH] Format-patch applied successfully"
  else
    log "[PATCH] Format-patch application had issues (continuing)"
  fi

  log "[PRECOMMIT] Running pre-commit hooks"
  if pre-commit run -a 2>/dev/null; then
    git add -A
    git commit -m "[IMP] $module_name: pre-commit auto fixes" --no-verify || log "[WARN] Pre-commit commit skipped (no changes)"
  fi

  log "=== Migration Complete ==="
  log "Log saved to: $LOG_FILE"
}

main "$@"