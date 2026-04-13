---
name: odoo-tests
description: Guide for running Odoo unit tests in the development environment. Use this when asked to run, debug, or execute Odoo module tests.
---

# Odoo Tests Skill

Purpose: Write, improve and iterate on Odoo module tests following local OCA-style testing patterns.

## When to Use

Use this skill when the task involves:
- Improving coverage for models, workflows, wizards or access rules
- Fixing broken tests
- Refactoring tests to match local conventions

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
- Use `Command.create(...)` and `Command.set(...)` for o2m/m2m setup
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

For running tests, first look for available information from GitHub workflows and module-level conventions in the target repository.

Run the narrowest relevant test target first (usually the changed test file), then expand scope if needed.

### Required Pre-Commit Gate

Before any `git commit`, the agent must run tests in the current agent session and confirm they pass.

- Do not commit if no test command has been executed in this session.
- Do not commit if the latest relevant test run failed.
- If tests cannot be executed (environment/tooling blocker), stop and report `manual_review_required` instead of committing.
- If the user explicitly asks to commit without tests, call out the risk and require confirmation before proceeding.

The commit gate is satisfied only when all of the following are present in the session output:

- Exact test command(s) that were executed
- Exit status/result for each command
- Short pass/fail summary mapped to changed files or scenarios

Use this command structure for a single test file:

```bash
/src/odoo/odoo-bin \
  --config=/src/config/odoo.conf \
  --dev=all \
  --stop-after-init \
  --test-file=<absolute_path_to_test_file> \
  --database=db18_test_<module> \
  --db_host=mydb \
  --db_user=odoo \
  --db_password=myodoo \
  --init=<module> \
  --update=<module>
```

For iterative fixes, re-run the failing file first; when green, run any broader target required by CI policy in the repository.

### Failure Handling
For each failure:
1. Read the traceback fully.
2. Ignore "Detect unreleased dependencies" failures.
3. Decide whether the problem is fixture setup, expectation mismatch, or a real bug.
4. Fix the narrowest issue.
5. Re-run the failing file.
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