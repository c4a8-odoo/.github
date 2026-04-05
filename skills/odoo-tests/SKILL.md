# Odoo Tests Skill

Purpose: Write, improve, run, and iterate on Odoo module tests following local OCA-style testing patterns.

## When to Use

Use this skill when the task involves:
- Adding new `test_*.py` files
- Improving coverage for models, workflows, wizards, or access rules
- Fixing broken tests
- Refactoring tests to match local conventions

## Core Rules

- Use Odoo's test framework, not pytest
- Prefer `TransactionCase` or an existing domain-specific base class
- Use `setUpClass` for expensive shared fixtures
- Never depend on demo data unless it is explicitly part of installed dependencies and stable
- Fix test code first when failures are caused by bad fixtures or wrong expectations
- Do not weaken implementation to satisfy tests

## Execution Rules

> **CRITICAL**: Always invoke `odoo-bin` via `/usr/bin/python3 /src/odoo/odoo-bin`. **Never call `/src/odoo/odoo-bin` directly as a standalone script** — doing so will fail with missing module errors because the system Python is not used.

Always run tests through `odoo-bin`, matching the workspace launch configuration.

Single test file:
```bash
/usr/bin/python3 /src/odoo/odoo-bin \
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

All module tests:
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

### Failure Handling
For each failure:
1. Read the traceback fully.
2. Decide whether the problem is fixture setup, expectation mismatch, or a real bug.
3. Fix the narrowest issue.
4. Re-run the failing file.
5. Repeat until green or until a genuine implementation defect is isolated.

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
- Exact test command(s) executed
- Pass/fail result summary
- Any real implementation bugs found during test execution
