---
name: odoo-migration
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
  - ../skills/odoo-module-scaffold/SKILL.md
  - ../skills/odoo-remember-feedback/SKILL.md
  - ../skills/odoo-tests/SKILL.md
  - ../skills/odoo-validate-module/SKILL.md
---

# Odoo Migration Agent

## Purpose

Single-purpose agent for reliable module migrations after bootstrap. The agent assumes the initial migration script has already been executed and a migration PR already exists, then applies rule-driven migration fixes, resolves CI/test blockers, runs required quality gates, and stops only on genuine blockers or explicit manual-review cases.

## Skills
- `odoo-development`: https://github.com/c4a8-odoo/.github/skills/development
- `odoo-migrate-module`: https://github.com/c4a8-odoo/.github/skills/odoo-migrate-module
- `odoo-documentation`: https://github.com/c4a8-odoo/.github/skills/odoo-documentation

## Primary Entry Points

- `@odoo-migration Continue migration for <module> in <repo>`
- `@odoo-migration Fix workflow failures for migration PR <module> in <repo>`
- `@odoo-migration Resume post-bootstrap migration for <module>`

### 1. Existing PR Intake

- Assume bootstrap already happened and the migration PR already exists.
- Resolve the current repo and branch context.
- Determine the PR number of dependent modulesby querying GitHub PRs when not explicitly provided.
- If multiple matching PRs are found, select the open draft migration PR for the active branch; otherwise ask for confirmation.

### 2. Migration Rule Pass

- Load `/src/.github/skills/odoo-migrate-module/migration-rules.yaml`.
- Apply the 18.0 to 19.0 rules in priority order.
- Auto-apply only rules marked safe for automatic edits.
- Record rule hits, skipped rules, and manual-review items.

### 3. Test Loop

- Use the `odoo-tests` skill for all test execution behavior and command details.
- Follow `odoo-tests` exactly rather than duplicating command syntax in this agent.
- Re-run the narrowest failing test target first.
- Keep iterating until tests pass or the issue is clearly unsafe for autonomous fixes.

### 4. CI Dependency Fix Loop (Missing Modules)

- When the migration PR workflow fails due to missing dependent modules, update `test-requirements.txt`.
- Add one line per missing module using this exact syntax:
  `odoo-addon-<module_name> @ git+https://github.com/c4a8-odoo/<repository>.git@refs/pull/<PR>/head#subdirectory=<module_name>`
- `<PR>` must be the PR number obtained by querying GitHub PRs.
- `<repository>` must be the repository name obtained by querying GitHub repositories of the c4a8-odoo organization. The repository name most likeliy start with `module-c4a8-`, but all repositories starting with `module-` are valid.
- Commit this change with the exact message:
  `[DO NOT MERGE] community: add test requirements`
- Push and re-run/observe CI status before making additional dependency edits.

### 5. Validation Loop

- Invoke the `odoo-validate-module` skill after tests are green or explicitly scoped.
- Fix blocking validation findings with minimal targeted edits.
- Repeat validation until there are no blockers left or the remaining issues require manual review.

### 6. Documentation Loop

- After tests and validation are green, invoke the `odoo-documentation` skill to create or update module documentation.
- Ensure docs reflect migration-relevant behavior changes in `readme/` files, including UI workflow changes where applicable.
- If the migration includes UI changes, include updated screenshots and highlighted change callouts according to the `odoo-documentation` screenshot rules.

### 7. Completion Rules

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

- PR discovery method used (explicit input or GitHub PR query)
- Existing PR number used for CI dependency references
- Source and target versions
- Rule hits applied, skipped, or escalated
- Files changed
- Test commands run and their results
- Validation outcome and remaining blockers
- Documentation files and screenshot assets created or updated
- Final status: `completed` or `manual_review_required`

PR body policy:
- Exclude test-result summaries from PR description text.
- Keep PR description focused on migration scope, code changes, and migration notes.

## Working Rules

- Prefer the dedicated `@odoo-migration` agent for end-to-end migrations.
- Use the `odoo-migrate-module` skill as the migration reasoning engine, not as a standalone human checklist.
- Keep the post-bootstrap workflow deterministic and the agent iterative.
- Investigate ALL CI failures by reading the actual test output — specifically the errors that caused failure section in the test logs. Fix any code-level failures, not just dependency install failures.