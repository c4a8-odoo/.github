---
name: odoo-migrate-module
description: Migrate Odoo modules between versions by a rule driven workflow.
---

# Odoo Migrate Module Skill

Purpose: Rule-driven migration engine to update Odoo modules from one version to the next (e.g. 15.0 -> 16.0, 16.0 -> 17.0, etc.), with structured state management and clear escalation gates.

## When to Use

Use this skill when the task involves:
- Applying version-specific migration rules to a module that has already been bootstrapped into the target branch
- Performing focused migration edits inside an existing migration run
- Driving post-bootstrap migration work before tests and validation
- Producing a structured migration status instead of a prose-only checklist

Prefer the `@odoo-migration` agent for end-to-end migrations. Use this skill directly only when the migration has already been scoped and you are working inside that orchestration flow.

## Current Supported Rule Families

- `15.0 -> 16.0`: `./resources/migration-rules-15.0-16.0.yaml` 
- `16.0 -> 17.0`: `./resources/migration-rules-16.0-17.0.yaml` 
- `17.0 -> 18.0`: `./resources/migration-rules-17.0-18.0.yaml` 
- `18.0 -> 19.0`: `./resources/migration-rules-18.0-19.0.yaml` 

When the rules above are not sufficient to complete the migration, use these model specific extended rules:
- `18.0 -> 19.0`: In `https://github.com/OCA/OpenUpgrade/tree/19.0/openupgrade_scripts/scripts` you may find module specific migration scripts for OCA and Odoo modules.
- `18.0 -> 19.0`: `./resources/migration-rules-odoo-18-19.md`
- `18.0 -> 19.0`: `./resources/migration-rules-enterprise-18-19.md`

## Required Inputs

Capture or infer:
- Module module name
- Repository path and active branch
- Source version and target version
- Current stage of the migration run and any prior blockers

## Primary Entry Points

- `Migrate <module> from <old_version> to <version>`
- `Continue migration for <module>`
- `Fix workflow failures for migration PR <module>`


### 0. Migration State Detection

If no direct entry point is provided, determine where the migration stands by inspecting the **live repository state**. Do not rely on any state files.

Detect state by examining:
- Whether a `[MIG] <module_name>: Migration to <version>` commit is present on the working branch, contiune with stage 

- Whether a the branch `<version>-mig-<module_name>` or a PR `[<version>][MIG] <module_name>:` exists on the remote.
- When the currenct branch has

- The diff of all commits **after** the `[MIG]` commit: which rule-driven, fix, or dependency commits have already been applied.
- The CI/test workflow status of the migration PR (if one exists): green, failing, or not yet run.

Map findings to one of these states and resume from the corresponding step:

| Detected State | Indicator | Resume at |
|---|---|---|
| `not_started` | No migration branch exists on remote | Step 1 (Bootstrap) |
| `bootstrapped` | `[MIG]` commit present, PR draft or no CI run yet | Step 2 (PR Intake) |
| `ci_failing` | PR exists, CI workflow is red | Step 4 (Test Loop) or Step 5 (CI Dependency) based on failure type |
| `tests_green` | CI green, validation not yet done | Step 6 (Validation Loop) |
| `validation_green` | Validation passes, docs not yet created | Step 7 (Documentation Loop) |
| `completed` | All loops green, final report already produced | Report current state and stop |

Document the detected state and the evidence used before proceeding.

### 1. Bootstrap Migration Branch

Only run this step when state detection finds `not_started`.

Run the migration script below with the correct parameters from a dedicated migration working branch named `<new_version>-mig-<module_name>`, created from `<new_version>`.
Before executing the script, make sure to fetch the full history from the remote to ensure the source and target branches are up to date.

- You have to use the migration script. Never copy the files manually.
- Do not limit the count of commits you fetch or apply because incompilete history lead to incorrect state and migration failures.
- While checked out on `<new_version>-mig-<module_name>`, pass `source_branch=<old_version>` and `target_branch=<new_version>` to the script so patch generation is based on the version branches, not on the temporary working branch.
- Do not squash, rebase, or re-create script-applied commits manually.
- After script execution, verify commit preservation:
  1) compute expected patch count for the module from `<target_branch>..<source_branch>` before apply,
  2) compute commits added by bootstrap on the migration branch,
  3) ensure the bootstrap-added commits contain the full script patch series (optionally plus the pre-commit autofix commit).
- If commit counts do not align or patch subjects are collapsed into a single commit, stop and escalate as `manual_review_required`.

`migration-oca.sh`: https://github.com/c4a8-odoo/.github/blob/main/skills/odoo-migrate-module/scripts/migration-oca.sh
Usage: ./migration-oca.sh [old_version] [new_version] [module] [source_branch] [target_branch]
[old_version] : The version you are migrating from (e.g. 18.0)
[new_version] : The version you are migrating to (e.g. 19.0)
[module] : The name of the module to migrate (e.g. crm)
[source_branch] : The source branch for the migration (e.g. 18.0)
[target_branch] : The current working branch.

### 2. Existing PR Intake

- Resolve the current repo and branch context.
- Determine the PR number of dependent modules by querying GitHub PRs when not explicitly provided.
- If multiple matching PRs are found, select the open draft migration PR for the active branch; otherwise ask for confirmation.

### 3. Migration Rule Pass

- Load the odoo-migration skill `./skills/odoo-migrate-module/SKILL.md`.
- Auto-apply only rules marked safe for automatic edits.
- Record rule hits, skipped rules, and manual-review items.

### 4. Test Loop

- Use the `odoo-tests` skill for all test execution behavior and command details.
- Follow `odoo-tests` exactly rather than duplicating command syntax in this agent.
- Enforce the `odoo-tests` Required Pre-Commit Gate before any commit created by this workflow.
- Re-run the narrowest failing test target first.
- Keep iterating until tests pass or the issue is clearly unsafe for autonomous fixes.

### 5. CI Dependency Fix Loop (Missing Modules)

- When the migration PR workflow fails due to missing dependent modules, update `test-requirements.txt`.
- If the user explicitly provides an exact dependency line, use it verbatim and do not rewrite it.
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
- Update the existing PR with commits that resolve migration, CI, validation, and documentation issues.
- Produce one final report with the rule hits, files changed, commands executed, blockers resolved, and remaining manual items.
- If you fail pushing the commits to the remote branch, stop and report `manual_review_required` instead of trying to force pushes or creating new branches/PRs. Ask the calling agent to execute the push.

## Manual-Review Gates

Escalate to manual review when:

- Patch application left semantic conflicts
- A proposed replacement depends on call-site intent, especially `self._uid`, `toggle_active`, or `Domain` rewrites
- Tests keep failing after narrow, migration-focused fixes
- Validation blockers point to missing dependencies or broader architecture issues
- The next change would be an unrelated refactor rather than a migration fix

## Non-Goals

- Do not change copyright years
- Do not change original authorship metadata without cause
- Do not silently perform risky semantic refactors unrelated to the migration
- Do not mark the migration as successful before both tests and validation have passed or been explicitly escalated
- Do not squash commits from the migration script

## Output Expectations

After using this skill, provide:
- State source used for the run, including the state file path when present
- Source and target versions
- Bootstrap commit-preservation evidence (expected patch count, applied commit count, and whether any squash/collapse was detected)
- Rules applied, skipped, or escalated
- Files changed
- Tests run and results
- Validation status and remaining blockers
- Documentation files and UI screenshot assets created or updated
- Final status: `completed` or `manual_review_required`

## PR Description Policy

When this skill contributes to PR creation text (directly or via `@odoo-migration`):
- Keep PR descriptions limited to migration scope, key code changes, and relevant notes.
- Do not include a dedicated `Test Results` section.
- Do not add lines like `All tests passing` or detailed validation output to the PR body.
- Report test/validation outcomes in execution logs or chat output instead.
