---
name: odoo-migrate-module
description: Rule-driven Odoo module migration skill for migrations between 15.0 and 19.0.
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

- `15.0 -> 16.0`: `./migration-rules-15.0-16.0.yaml` 
- `16.0 -> 17.0`: `./migration-rules-16.0-17.0.yaml` 
- `17.0 -> 18.0`: `./migration-rules-17.0-18.0.yaml` 
- `18.0 -> 19.0`: `./migration-rules-18.0-19.0.yaml` 

When the rules above are not sufficient to complete the migration, use these model specific extended rules:
- `18.0 -> 19.0`: `./migration-rules-odoo-18-19.md`
- `18.0 -> 19.0`: `./migration-rules-enterprise-18-19.md`

## Required Inputs

Capture or infer:
- Module path and module name
- Repository path and active branch
- Source version and target version
- Current stage of the migration run and any prior blockers

## State-Aware Workflow

This skill is expected to operate on a migration run that moves through explicit stages.

- `ready_for_ai`: bootstrap finished, migration edits should start
- `ai_migration_done`: rule-driven edits applied, tests should run next
- `tests_pending`: the migration needs targeted test execution and fixes
- `tests_green`: tests are passing, validation should run next
- `validation_pending`: validation still needs to run or be re-run
- `validation_green`: validation blockers are cleared
- `manual_review_required`: automation stopped because the remaining work is unsafe or ambiguous
- `completed`: migration finished with green quality gates

## Execution Contract

1. Read the migration state file when it exists and confirm the run is resumable.
2. Inspect the module files that were bootstrapped into the target branch.
3. Load the structured rules for the requested version path.
4. Apply only the rules that are safe for autonomous edits.
5. Record rule hits, skipped rules, and manual-review items.
6. Set up the next stage for the `odoo-tests` loop.
7. Hand off to `odoo-validate-module` only after tests are green or explicitly narrowed.
8. After validation is green, hand off to `odoo-documentation` to create or update migration-relevant module documentation.
9. Stop and escalate instead of forcing risky semantic rewrites.


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

## Output Expectations

After using this skill, provide:
- State source used for the run, including the state file path when present
- Source and target versions
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
