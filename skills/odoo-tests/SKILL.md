---
name: odoo-tests
description: Guide for writing and running Odoo tests.
---

# Odoo Tests Skill

Purpose: Write, improve and iterate on Odoo module tests following local OCA-style testing patterns.

## When to Use

Use this skill when the task involves:
- Improving coverage for models, workflows, wizards or access rules
- Fixing broken tests
- Refactoring or adapting tests

## Test File Structure

Odoo tests must follow the OCA convention:
- Place test files in `<module>/tests/` directory
- Test files must be named `test_*.py`
- The `tests/__init__.py` must import all test modules

Example test structure:
```
my_module/
├── tests/
│   ├── __init__.py    # imports test_my_module
│   └── test_my_module.py
```

## Core Rules

- Use Odoo's test framework, not pytest
- Prefer `TransactionCase` or an existing domain-specific base class
- Use `setUpClass` for expensive shared fixtures
- Never depend on demo data
- Fix test code first when failures are caused by bad fixtures or wrong expectations
- Do not weaken implementation to satisfy tests

## Test Design Guidance

### Preferred Patterns
- Reuse an existing local base class before introducing a new one
- Use `Form(...)` for wizard flows and onchange-driven UI behavior
- Add docstrings to test methods
- Assert on business outcomes, not only raw field values
- Mock external HTTP calls narrowly with `unittest.mock.patch`

### What to Cover
- Create/write/unlink flows where business logic exists
- Constraints and validation errors
- Access rights and record rules
- Workflow transitions and side effects
- Wizard execution and returned actions
- Computed fields and onchange behavior
- Cron-triggered or scheduled effects when relevant

## Execution Rules

Use the skill script as the single entrypoint for test execution.

When tests must run, execute:

```bash
bash skills/odoo-tests/scripts/run-test-workflow.sh
```

This script replays the provided `test.yml` test job on the local working tree and runs the same command order used in CI:

1. `oca_install_addons`
2. `manifestoo -d . check-licenses`
3. `manifestoo -d . check-dev-status --default-dev-status=Beta`
4. `oca_init_test_database`
5. `oca_run_tests`

The script also provisions local PostgreSQL with workflow-compatible credentials and runs inside the OCA CI image with `OCA_ENABLE_CHECKLOG_ODOO=1`.

### Script Options

- Run both matrix images (Odoo + OCB):

```bash
bash skills/odoo-tests/scripts/run-test-workflow.sh --with-ocb
```

- Restrict tests to one module:

```bash
bash skills/odoo-tests/scripts/run-test-workflow.sh --include <module>
```

- Override the test database name:

```bash
bash skills/odoo-tests/scripts/run-test-workflow.sh --db <database>
```

- Override the Python version:

```bash
bash skills/odoo-tests/scripts/run-test-workflow.sh --python-version <python_version>
```

- Override the Odoo version:

```bash
bash skills/odoo-tests/scripts/run-test-workflow.sh --odoo-version <odoo_version>>
```

### Iteration Rules

- Start with the default command (Odoo image only) while iterating.
- Use `--include <module>` to narrow scope when appropriate.
- Use `--with-ocb` before final validation when CI parity is needed.
- If dependency or manifest checks fail, rerun from the default script command after fixing the issue.
- If only test logic changed, rerun the same command first, then broaden scope if required.

### Local Scope vs CI Scope

- Do not run `oca_export_and_push_pot` from this skill script.
- Keep "Detect unreleased dependencies" as an optional, separate local precheck when needed.
- If Docker or Podman is unavailable in the environment, stop and report the blocker instead of switching to ad-hoc raw `odoo-bin` execution.

### Failure Handling
For each failure:
1. Read the traceback fully.
2. Ignore "Detect unreleased dependencies" failures.
3. Decide whether the problem is fixture setup, expectation mismatch, or a real bug.
4. Fix the narrowest issue.
5. Re-run `bash skills/odoo-tests/scripts/run-test-workflow.sh` with the narrowest useful flags.
6. Repeat until green or until a genuine implementation defect is isolated.

## Local Conventions

- Align with neighboring tests in the target module first
- Prefer concise but explicit fixtures
- Use `self.env.ref(...)` only for stable dependency XML IDs
- Avoid broad factory abstractions unless the suite already uses them
- Disable tracking in test context when noise or performance matters

## Output Expectations

After using this skill, provide:
- Test files added or changed
- Scenarios now covered
- Pass/fail result summary