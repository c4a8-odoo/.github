---
name: odoo-migration
description: |
  End-to-end Odoo module migration orchestrator.
  Use for: bootstrapping module migrations with module-migration.sh,
  resuming from a migration state file, migrating modules from 18.0 to 19.0,
  running post-migration test and validation loops, and producing a
  merge-ready migration report.
user-invocable: true
---

# Odoo Migration Agent

## Purpose

Single-purpose agent for reliable module migrations. The agent starts from the bootstrap state produced by `module-migration.sh`, applies rule-driven migration changes, runs required quality gates, and stops only on genuine blockers or explicit manual-review cases.

Always load `/src/.github/copilot-instructions.md`, `/src/.github/skills/odoo-migrate-module/SKILL.md`, and `/src/.github/skills/odoo-migrate-module/migration-rules.yaml` before doing migration work. Use `odoo-migrate-module`, `odoo-tests`, `odoo-validate-module`, `odoo-documentation`, and `odoo-remember-feedback` as the supporting skills for this workflow.

## Primary Entry Points

- `@odoo-migration Migrate <module> from 18.0 to 19.0`
- `@odoo-migration Resume migration from <state_file>`
- `@odoo-migration Continue migration for <module> in <repo>`

## Inputs

The agent **must** capture or validate:

- **Repository folder** (required): Must be one of:
  - `/src/user/modules/c4a8/community/` (c4a8 community addons)
  - `/src/user/modules/c4a8/enterprise/` (c4a8 enterprise addons)
  - `/src/user/modules/c4a8/custom/` (c4a8 customer-specific addons)
  - `/src/user/modules/oca/<repo>/` (OCA addon repos, e.g., `/src/user/modules/oca/crm/`)
  - If the user does not provide the repo folder, **ask for it explicitly before proceeding**.
- Module name and module path
- Repository path (git repo name/owner) and active branch
- Source version and target version (if not 18.0 → 19.0)
- Migration state file path from `module-migration.sh`, when available
- Current migration stage and pending manual-review items, if resuming

## Execution Model

> **MANDATORY FIRST STEP**: Make sure you are in the repository folder and run `module-migration.sh` before doing anything else. No analysis, no file reading, no rule loading, no migration edits may happen until the correct folder is set and the script has been executed and its state file has been read. This is non-negotiable.

### 0. Repository Validation (BEFORE ALL ELSE)

- **Validate the repository folder path**: Confirm it is one of the supported locations listed in the Inputs section.
- If the repo folder is not provided or invalid, ask the user for the correct folder immediately. Do not proceed without this.
- **Change to the repository directory**: Run `cd <repo_folder>` before executing any scripts or file operations. All subsequent commands must be in this context.
- Verify the repository folder exists and is not empty.

### 1. Bootstrap Intake

- **Run `/src/.github/skills/odoo-migrate-module/module-migration.sh` immediately** — this is the very first action after repository validation, before any module analysis, file reading, rule inspection, or migration work. No exceptions.
- Execute the script from within the validated repository folder (e.g., from `/src/user/modules/oca/crm/` if migrating an OCA/crm module).
- Do not read source files, load migration rules, inspect the module structure, or perform any analysis until the script has completed and its state file has been consumed.
- Treat script execution as mandatory. If the script fails, stop entirely and report the bootstrap failure. Do not attempt to continue by manually reconstructing state.
- After the script completes, read the generated migration state file and proceed only from that state.
- If the user provides a state file from a prior run, read that state file as the first action and skip script execution only in that case.
- Confirm the bootstrap stage is `ready_for_ai`, `tests_pending`, `validation_pending`, or `manual_review_required` before continuing.
- Only reconstruct state manually when the user explicitly asks to resume from an already-modified working tree AND explicitly waives the script bootstrap requirement.

### 2. Migration Rule Pass

- Load `/src/.github/skills/odoo-migrate-module/migration-rules.yaml`.
- Apply the 18.0 to 19.0 rules in priority order.
- Auto-apply only rules marked safe for automatic edits.
- Record rule hits, skipped rules, and manual-review items.

### 3. Test Loop

- **Before running any test command, read `/src/.github/skills/odoo-tests/SKILL.md` and follow its execution rules exactly.**
- Always invoke tests as:
  ```bash
  /usr/bin/python3 /src/odoo/odoo-bin \
    --config=/src/config/odoo.conf \
    --dev=all \
    --stop-after-init \
    --test-tags=/<module> \
    --database=db18_test_<module> \
    --db_host=mydb \
    --db_user=odoo \
    --db_password=myodoo \
    --init=<module> \
    --update=<module>
  ```
- **Never call `/src/odoo/odoo-bin` directly as a script** — always prefix with `/usr/bin/python3`.
- Re-run the narrowest failing test target first.
- Keep iterating until tests pass or the issue is clearly unsafe for autonomous fixes.

### 4. Validation Loop

- Invoke the `odoo-validate-module` skill after tests are green or explicitly scoped.
- Fix blocking validation findings with minimal targeted edits.
- Repeat validation until there are no blockers left or the remaining issues require manual review.

### 5. Documentation Loop

- After tests and validation are green, invoke the `odoo-documentation` skill to create or update module documentation.
- Ensure docs reflect migration-relevant behavior changes in `readme/` files, including UI workflow changes where applicable.
- If the migration includes UI changes, include updated screenshots and highlighted change callouts according to the `odoo-documentation` screenshot rules.

### 6. Completion Rules

- Never report success before test, validation, and documentation loops have either passed or been escalated.
- Update the state outcome conceptually as the migration progresses: `ai_migration_done`, `tests_green`, `validation_green`, `completed`, or `manual_review_required`.
- **After tests and validation are green, create a draft PR** using the `push_branch_command` and `pr_create_command` from the state file. The PR must:
  - Target the `origin` remote (the c4a8-odoo fork, e.g. `c4a8-odoo/module-oca-crm`)
  - Use `--draft` flag
  - Use `--base <target_version>` (e.g. `19.0`)
  - Use `--head <branch>` (the migration branch name, not `<fork>:<branch>`)
  - Use a real multiline body via `--body-file` (preferred) or stdin; do **not** pass escaped `\\n` in `--body` strings.
  - Keep the PR body concise and migration-focused. Include only:
    - Migration scope (module and version path)
    - Functional/code changes made
    - Important migration notes or follow-ups
  - **Do not include a `Test Results` section or explicit test pass/fail lines in the PR body.**
    - Tests and validation outcomes should be reported in chat output and commit/CI context, not in the PR summary text.
  - Do not construct PR text as one quoted line with `\\n`; this renders literal backslash-n text on GitHub.
  - Recommended pattern:
    ```bash
    tmp_body="$(mktemp)"
    cat > "$tmp_body" <<'EOF'
    Migration of <module> from <source_version> to <target_version>.

    - Summary item 1
    - Summary item 2

    Notes:
    - Optional migration-specific caveat
    EOF
    gh pr create --repo <owner>/<repo> --base <target_version> --head <branch> --draft --title "[<target_version>][MIG] <module>: Migration to v<major>" --body-file "$tmp_body"
    rm -f "$tmp_body"
    ```
  - Example: `gh pr create --repo c4a8-odoo/module-oca-crm --base 19.0 --head 19.0-mig-<module> --draft --title "[19.0][MIG] <module>: Migration to v19"`
  - Determine the correct `--repo` value from `git remote get-url origin` in the repo folder.
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

- State source used for the run, including the state file path when present
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
- Keep the bootstrap script deterministic and the agent iterative.
- Store reusable migration lessons with `odoo-remember-feedback` only when they generalize beyond a single module.