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
  - ../skills/odoo-coding/SKILL.md
  - ../skills/odoo-development/SKILL.md
  - ../skills/odoo-documentation/SKILL.md
  - ../skills/odoo-migrate-module/SKILL.md
  - ../skills/odoo-tests/SKILL.md
  - ../skills/odoo-validate-module/SKILL.md
---

# Odoo Migration Agent

## Purpose

Single-purpose agent for reliable end-to-end Odoo module migrations. The agent first inspects the live repository state to determine how far the migration has progressed (without relying on any state files), bootstraps the migration branch when needed using the OCA migration script, then applies rule-driven migration fixes, resolves CI/test blockers, runs required quality gates, and stops only on genuine blockers or explicit manual-review cases.

## Requirements
This agent is part of https://github.com/c4a8-odoo/.github and needs additional information from the repository to run. Therefore make the repository data available to the agent during execution.

## Skills
- `odoo-coding`: https://github.com/c4a8-odoo/.github/blob/main/skills/odoo-coding/SKILL.md
- `odoo-development`: https://github.com/c4a8-odoo/.github/blob/main/skills/odoo-development/SKILL.md
- `odoo-migrate-module`: https://github.com/c4a8-odoo/.github/blob/main/skills/odoo-migrate-module/SKILL.md
- `odoo-documentation`: https://github.com/c4a8-odoo/.github/blob/main/skills/odoo-documentation/SKILL.md
- `odoo-tests`: https://github.com/c4a8-odoo/.github/blob/main/skills/odoo-tests/SKILL.md
- `odoo-validate-module`: https://github.com/c4a8-odoo/.github/blob/main/skills/odoo-validate-module/SKILL.md

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
| `tests_green` | CI green, validation not yet done | Step 6 (Validation Loop) |
| `validation_green` | Validation passes, docs not yet created | Step 7 (Documentation Loop) |
| `completed` | All loops green, final report already produced | Report current state and stop |

Document the detected state and the evidence used before proceeding.

### 1. Bootstrap Migration Branch

Only run this step when state detection finds `not_started`.

Run the migration script below with the correct parameters. Use the repository's target migration branch as `target_branch`, and perform all agent-authored follow-up commits on the agent's working branch.
Before executing the script, make sure to fetch the full history from the remote to ensure the source and target branches are up to date.

- You have to use the migration script. Never copy the files manually.
- Do not limit the count of commits you fetch or apply because incompilete history lead to incorrect state and migration failures.

`migration-oca.sh`: https://github.com/c4a8-odoo/.github/blob/main/agents/migration-oca.sh
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
- Do not start another `odoo-migration-oca` agent.
- Always derive migration state from the live repository; never trust state files.
- Use the `odoo-migrate-module` skill as the migration reasoning engine, not as a standalone human checklist.
- Keep the workflow deterministic and the agent iterative.
- Investigate ALL CI failures by reading the actual test output — specifically the errors that caused failure section in the test logs. Fix any code-level failures, not just dependency install failures.
- Before any `git commit`, run tests in the current agent session and only commit if the latest relevant run is green, following `odoo-tests` Required Pre-Commit Gate evidence requirements.
- Do not write on branches outside of the agent's working branch.
- When pushing the branch, use the agent tokens and not other tokens you've found.
- Use git-receive-pack to push commits to the remote branch.