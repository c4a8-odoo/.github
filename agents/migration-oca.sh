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

check_tools() {
  local missing_tools=0
  for tool in git gh pre-commit; do
    if ! command -v "$tool" &>/dev/null; then
      echo "ERROR: Required tool '$tool' not found in PATH"
      missing_tools=$((missing_tools + 1))
    fi
  done
  if [ $missing_tools -gt 0 ]; then
    echo "ERROR: $missing_tools required tool(s) missing. Cannot continue."
    exit 1
  fi
  log "All required tools found: git, gh, pre-commit"
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

  check_tools

  cd "$source_path" || { log "[ERROR] Cannot cd to $source_path"; return 1; }

  git am --abort 2>/dev/null || true
  git reset --hard HEAD
  git clean -fd

  local branch_name="$version-mig-$module_name"

  if git show-ref --verify --quiet "refs/heads/$branch_name"; then
    log "[EXISTS] Branch $branch_name already exists for $module_name"
    return
  fi

  log "[CREATE] Creating branch $branch_name"
  git fetch "$user_org" "$target_branch" "$source_branch" || { log "[ERROR] Failed to fetch branches"; return 1; }
  git checkout -b "$branch_name" "$user_org/$target_branch" || { log "[ERROR] Failed to create branch"; return 1; }

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

  log "[VERSION] Updating version to $version"
  if [ -f "$module_name/__manifest__.py" ]; then
    sed -i "s/\"$version_old\.[0-9]*\.[0-9]*\.[0-9]*\"/\"$version.1.0.0\"/g" "$module_name/__manifest__.py"
    git add --all
    git commit -m "[MIG] $module_name: Migration to $version" --no-verify || log "[WARN] Version commit skipped (no changes)"
  else
    log "[WARN] __manifest__.py not found for $module_name"
  fi

  log "[PUSH] Pushing branch $branch_name"
  if git push "$user_org" "$branch_name" --set-upstream; then
    log "[SUCCESS] Module $module_name migrated successfully"
    gh pr create --title "[$version][MIG] $module_name" --body-file /src/dev/migration/migration-pr-body.md --base $target_branch -d
  else
    log "[ERROR] Failed to push branch $branch_name"
    return 1
  fi

  log "=== Migration Complete ==="
  log "Log saved to: $LOG_FILE"
}

main "$@"