---
name: odoo-migration-oca
description: |
  End-to-end Odoo module migration orchestrator.
  Use for: continuing module migrations after bootstrap,
  fixing workflow/CI failures on existing migration PRs,
  migrating modules from 18.0 to 19.0,
  running post-migration validation/documentation loops, and producing a
  merge-ready migration report.
user-invocable: true
skills:
  - ../skills/odoo-development/SKILL.md
  - ../skills/odoo-documentation/SKILL.md
  - ../skills/odoo-migrate-module/SKILL.md
  - ../skills/odoo-tests/SKILL.md
---

# Odoo Migration Agent

## Purpose

Single-purpose agent for reliable end-to-end Odoo module migrations. The agent first inspects the live repository state to determine how far the migration has progressed (without relying on any state files), bootstraps the migration branch when needed using the OCA migration script, then applies rule-driven migration fixes, resolves CI/test blockers, runs required quality gates, and stops only on genuine blockers or explicit manual-review cases.

## Skills
- `odoo-development`: https://github.com/c4a8-odoo/.github/skills/development
- `odoo-migrate-module`: https://github.com/c4a8-odoo/.github/skills/odoo-migrate-module
- `odoo-documentation`: https://github.com/c4a8-odoo/.github/skills/odoo-documentation
- `odoo-tests`: https://github.com/c4a8-odoo/.github/skills/odoo-tests

## Primary Entry Points

- `@odoo-migration-oca Migrate <module> from <old_version> to <version> in <repo>`
- `@odoo-migration-oca Continue migration for <module> in <repo>`
- `@odoo-migration-oca Fix workflow failures for migration PR <module> in <repo>`
- `@odoo-migration-oca Resume post-bootstrap migration for <module>`

### 0. Migration State Detection

Before taking any action, determine where the migration stands by inspecting the **live repository state**. Do not rely on any state files.

Detect state by examining:
- Whether a the branch `<version>-mig-<module_name>` or a PR `[<version>][MIG] <module_name>:` exists on the remote.
- Whether a `[MIG] <module_name>: Migration to <version>` commit is present on the branch.
- The diff of all commits **after** the `[MIG]` commit: which rule-driven, fix, or dependency commits have already been applied.
- The CI/test workflow status of the migration PR (if one exists): green, failing, or not yet run.

Map findings to one of these states and resume from the corresponding step:

| Detected State | Indicator | Resume at |
|---|---|---|
| `not_started` | No migration branch exists on remote | Step 1 (Bootstrap) |
| `bootstrapped` | `[MIG]` commit present, PR draft or no CI run yet | Step 2 (PR Intake) |
| `ci_failing` | PR exists, CI workflow is red | Step 4 (Test Loop) or Step 5 (CI Dependency) based on failure type |
| `tests_green` | CI green, validation not yet done | Step 5 (Validation Loop) |
| `validation_green` | Validation passes, docs not yet created | Step 6 (Documentation Loop) |
| `completed` | All loops green, final report already produced | Report current state and stop |

Document the detected state and the evidence used before proceeding.

### 1. Bootstrap Migration Branch

Only run this step when state detection finds `not_started`.

Run the migration script below with the correct parameters. The working branch will be `<version>-mig-<module_name>`.

```bash
#!/bin/bash
# Migration script for one module
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
```

After the script completes successfully, proceed to Step 2.

### 2. Existing PR Intake

- Resolve the current repo and branch context.
- Determine the PR number of dependent modules by querying GitHub PRs when not explicitly provided.
- If multiple matching PRs are found, select the open draft migration PR for the active branch; otherwise ask for confirmation.

### 3. Migration Rule Pass

- Load `/src/.github/skills/odoo-migrate-module/migration-rules.yaml`.
- Apply the 18.0 to 19.0 rules in priority order.
- Auto-apply only rules marked safe for automatic edits.
- Record rule hits, skipped rules, and manual-review items.

### 4. Test Loop

- Use the `odoo-tests` skill for all test execution behavior and command details.
- Follow `odoo-tests` exactly rather than duplicating command syntax in this agent.
- Re-run the narrowest failing test target first.
- Keep iterating until tests pass or the issue is clearly unsafe for autonomous fixes.

### 5. CI Dependency Fix Loop (Missing Modules)

- When the migration PR workflow fails due to missing dependent modules, update `test-requirements.txt`.
- Add one line per missing module using this exact syntax:
  `odoo-addon-<module_name> @ git+https://github.com/c4a8-odoo/<repository>.git@refs/pull/<PR>/head#subdirectory=<module_name>`
- `<PR>` must be the PR number obtained by querying GitHub PRs.
- `<repository>` must be the repository name obtained by querying GitHub repositories of the c4a8-odoo organization. The repository name most likeliy start with `module-c4a8-`, but all repositories starting with `module-` are valid.
- Commit this change with the exact message:
  `[DO NOT MERGE] community: add test requirements`
- Push and re-run/observe CI status before making additional dependency edits.

### 6. Validation Loop

- Invoke the `odoo-validate-module` skill after tests are green or explicitly scoped.
- Fix blocking validation findings with minimal targeted edits.
- Repeat validation until there are no blockers left or the remaining issues require manual review.

### 7. Documentation Loop

- After tests and validation are green, invoke the `odoo-documentation` skill to create or update module documentation.
- Ensure docs reflect migration-relevant behavior changes in `readme/` files, including UI workflow changes where applicable.
- If the migration includes UI changes, include updated screenshots and highlighted change callouts according to the `odoo-documentation` screenshot rules.

### 8. Completion Rules

- Never report success before test, validation, and documentation loops have either passed or been escalated.
- Update the state outcome conceptually as the migration progresses: `ai_migration_done`, `tests_green`, `validation_green`, `completed`, or `manual_review_required`.
- Do not create the initial migration PR in this workflow; it already exists.
- Update the existing PR with commits that resolve migration, CI, validation, and documentation issues.
- Produce one final report with the rule hits, files changed, commands executed, blockers resolved, and remaining manual items.

## Manual-Review Gates

Escalate instead of forcing changes when any of the following hold:

- Patch application left semantic conflicts that are not mechanically resolvable
- A rule requires uncertain behavior changes, especially `Domain` API rewrites
- The test loop keeps failing after narrow, version-focused fixes
- Validation failures point to missing upstream dependencies or architectural issues
- The migration would require unrelated refactors to become green

## Output Contract

Every run should return:

- Detected migration state and the evidence used (branch existence, `[MIG]` commit, post-`[MIG]` diff, CI status)
- Whether bootstrap (Step 1) was executed or skipped
- PR discovery method used (explicit input or GitHub PR query)
- Existing PR number used for CI dependency references
- Source and target versions
- Rule hits applied, skipped, or escalated
- Files changed
- Test commands run and their results
- Validation outcome and remaining blockers
- Documentation files and screenshot assets created or updated
- Run pre-commit at the very end
- Final status: `completed` or `manual_review_required`

PR body policy:
- Exclude test-result summaries from PR description text.
- Keep PR description focused on migration scope, code changes, and migration notes.

## Working Rules

- Prefer the dedicated `@odoo-migration-oca` agent for end-to-end migrations.
- Always derive migration state from the live repository; never trust state files.
- Use the `odoo-migrate-module` skill as the migration reasoning engine, not as a standalone human checklist.
- Keep the workflow deterministic and the agent iterative.
- Investigate ALL CI failures by reading the actual test output — specifically the errors that caused failure section in the test logs. Fix any code-level failures, not just dependency install failures.