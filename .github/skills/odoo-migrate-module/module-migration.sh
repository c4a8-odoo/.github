#!/usr/bin/env bash
set -euo pipefail

# Generic OCA module migration bootstrap helper.
# Based on OCA migration how-to workflow:
# https://github.com/OCA/maintainer-tools/wiki/Migration-to-version-18.0
#
# Usage:
#   ./module-migration.sh <repo> <module> <source_version> <target_version> [user_org] [upstream_org]
# Example:
#   ./module-migration.sh server-tools base_revision 17.0 18.0 c4a8-odoo OCA
#
# Optional env:
#   MIGRATION_STATE_DIR=/path/to/state-dir   Override sidecar state directory
#   AUTO_STASH_LOCAL_CHANGES=0              Fail instead of auto-stashing dirty repos

if [[ $# -lt 4 || $# -gt 6 ]]; then
    echo "Usage: $0 <repo> <module> <source_version> <target_version> [user_org] [upstream_org]"
    exit 1
fi

repo="$1"
module="$2"
source_version="$3"
target_version="$4"
user_org="${5:-}"
upstream_org="${6:-OCA}"

branch="${target_version}-mig-${module}"
repo_url="https://github.com/${upstream_org}/${repo}"
script_invocation_dir="$(pwd)"
default_state_dir="/src/state/migration-state"
state_dir="${MIGRATION_STATE_DIR:-$default_state_dir}"
state_file="${state_dir}/${repo}__${module}__${target_version}.json"
current_stage="initialized"
auto_stash_local_changes="${AUTO_STASH_LOCAL_CHANGES:-1}"
stashed_changes="false"
stash_ref=""
initial_branch=""
mig_commit_cmd=""
push_branch_cmd=""
pr_create_cmd=""

mkdir -p "$state_dir"

info() {
    printf "\n[INFO] %s\n" "$1"
}

warn() {
    printf "\n[WARN] %s\n" "$1"
}

json_escape() {
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

write_state() {
    local stage="$1"
    local status="$2"
    local note="${3:-}"
    local repo_path=""
    local head_commit=""
    local pr_head=""

    current_stage="$stage"
    repo_path="$(pwd)"
    head_commit="$(git rev-parse HEAD 2>/dev/null || true)"

    if [[ -n "$user_org" ]]; then
        push_branch_cmd="git push -u ${user_org} HEAD:refs/heads/${branch}"
    else
        push_branch_cmd="git push -u origin HEAD:refs/heads/${branch}"
    fi

    mig_commit_cmd="git add --all && git commit -m \"[MIG] ${module}: Migration to ${target_version}\" --no-verify"

    if [[ -n "$user_org" ]]; then
        pr_head="${user_org}:${branch}"
    else
        pr_head="${branch}"
    fi

    pr_create_cmd="gh pr create --repo ${upstream_org}/${repo} --base ${target_version} --head ${pr_head} --title \"[${target_version}][MIG] ${module}: Migration to v${target_version%%.*}\""

    cat > "$state_file" <<EOF
{
  "schema_version": 1,
  "status": "$(json_escape "$status")",
  "stage": "$(json_escape "$stage")",
  "repo": "$(json_escape "$repo")",
  "module": "$(json_escape "$module")",
  "source_version": "$(json_escape "$source_version")",
  "target_version": "$(json_escape "$target_version")",
  "branch": "$(json_escape "$branch")",
  "repo_url": "$(json_escape "$repo_url")",
  "repo_path": "$(json_escape "$repo_path")",
  "state_file": "$(json_escape "$state_file")",
  "user_org": "$(json_escape "$user_org")",
  "upstream_org": "$(json_escape "$upstream_org")",
  "head_commit": "$(json_escape "$head_commit")",
    "initial_branch": "$(json_escape "$initial_branch")",
    "stashed_local_changes": "$(json_escape "$stashed_changes")",
    "stash_ref": "$(json_escape "$stash_ref")",
    "mig_commit_command": "$(json_escape "$mig_commit_cmd")",
    "push_branch_command": "$(json_escape "$push_branch_cmd")",
    "pr_create_command": "$(json_escape "$pr_create_cmd")",
  "suggested_pr_title": "$(json_escape "[${target_version}][MIG] ${module}: Migration to ${target_version}")",
  "next_action": "$(json_escape "Run @odoo-migration with this state file to continue the migration.")",
  "note": "$(json_escape "$note")"
}
EOF

    info "Updated migration state: ${state_file} (${stage}/${status})"
}

on_error() {
    local exit_code="$?"
    local note="Bootstrap failed while stage '${current_stage}'."

    if [[ -n "${BASH_COMMAND:-}" ]]; then
        note="${note} Last command: ${BASH_COMMAND}"
    fi

    write_state "$current_stage" "failed" "$note"
    exit "$exit_code"
}

trap on_error ERR

write_state "initialized" "running" "Bootstrap started."

initial_branch="$(git branch --show-current 2>/dev/null || true)"

if [[ -n "$(git status --porcelain)" ]]; then
    if [[ "$auto_stash_local_changes" != "1" ]]; then
        echo "Repository '$repo' has uncommitted changes and AUTO_STASH_LOCAL_CHANGES=0."
        echo "Commit/stash manually or rerun with AUTO_STASH_LOCAL_CHANGES=1."
        exit 1
    fi

    info "Repository has local changes. Auto-stashing before branch switch."
    git stash push --include-untracked -m "module-migration.sh:auto-stash:${module}:${target_version}:$(date -u +%Y%m%dT%H%M%SZ)"
    stash_ref="$(git stash list -1 --format='%gd')"
    stashed_changes="true"
fi

write_state "repository_ready" "running" "Repository cloned or reused."

info "Fetching latest refs"
git fetch --all --prune

if ! git show-ref --verify --quiet "refs/remotes/origin/${target_version}"; then
    echo "Target ref origin/${target_version} not found in ${repo_url}"
    exit 1
fi

if ! git show-ref --verify --quiet "refs/remotes/origin/${source_version}"; then
    echo "Source ref origin/${source_version} not found in ${repo_url}"
    exit 1
fi

info "Creating migration branch: ${branch}"
git checkout -B "$branch" "origin/${target_version}"

info "Applying module history from ${source_version}"
if ! git format-patch --keep-subject --stdout "origin/${target_version}..origin/${source_version}" -- "$module" | git am -3 --keep; then
    warn "Patch apply failed. Retrying with --ignore-whitespace as recommended by OCA wiki."
    git am --abort || true
    git format-patch --keep-subject --stdout "origin/${target_version}..origin/${source_version}" -- "$module" | git am -3 --keep --ignore-whitespace
fi
write_state "patch_applied" "running" "Source branch module history applied onto target branch."

info "Running pre-commit auto-fixes"
pre-commit run -a || true

if [[ -n "$(git status --porcelain)" ]]; then
    git add -A
    git commit -m "[IMP] ${module}: pre-commit auto fixes" --no-verify
else
    info "No pre-commit changes to commit."
fi

write_state "ready_for_ai" "awaiting_agent" "Bootstrap completed. Continue with the dedicated @odoo-migration agent."

info "Bootstrap complete. Next step: hand the state file to @odoo-migration."
printf '\nState file: %s\n' "$state_file"
printf 'Suggested prompt: @odoo-migration Resume migration from %s\n' "$state_file"
printf 'MIG commit command: %s\n' "$mig_commit_cmd"
printf 'Push branch command: %s\n' "$push_branch_cmd"
printf 'PR create command: %s\n' "$pr_create_cmd"

if [[ -n "$user_org" ]]; then
    info "The state file keeps your push target. The agent can use remote '${user_org}' later in the flow."
fi

if [[ "$stashed_changes" == "true" ]]; then
    info "Local changes were auto-stashed as ${stash_ref}."
    info "Apply later if needed with: git stash apply ${stash_ref}"
fi
