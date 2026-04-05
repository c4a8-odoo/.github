---
name: odoo-run-tests
description: Guide for running Odoo unit tests in the development environment. Use this when asked to run, debug, or execute Odoo module tests.
---

# Running Odoo Unit Tests

The development environment uses a Docker-based devcontainer with a dedicated `test` container for running Odoo unit tests.

## Prerequisites

- The devcontainer must be running (open the repository in VS Code with the Dev Containers extension)
- The `test` container is the active VS Code workspace container (service: `test`, workspace: `/src`)

## Running Tests via VS Code (Recommended)

1. Open the test file you want to run in VS Code (e.g., `/src/user/modules/my_module/tests/test_my_module.py`)
2. Use the **"Debug Tests"** launch configuration from the VS Code Run and Debug panel
3. The configuration automatically extracts the module name from the file path
4. Tests run against a dedicated test database (`db18_test_<module>`)

The "Debug Tests" launch configuration uses:
```
/src/odoo/odoo-bin
  --config=/etc/odoo/odoo.conf
  --dev=all
  --stop-after-init
  --test-file=<current_file>
  --database=db18_test_<module>
  --db_host=mydb
  --db_user=odoo
  --db_password=myodoo
  --init=<module>
  --update=<module>
  --screencasts=/src/screencasts
```

## Running Tests via Command Line

From inside the `test` container (connected via devcontainer), run:

> **CRITICAL**: Always invoke `odoo-bin` via `/usr/bin/python3 /src/odoo/odoo-bin`. Never call `/src/odoo/odoo-bin` directly as a standalone script — doing so will fail with missing module errors because the system Python is not used.

Single test file:
```bash
/usr/bin/python3 /src/odoo/odoo-bin \
  --config=/etc/odoo/odoo.conf \
  --dev=all \
  --stop-after-init \
  --test-file=<absolute_path_to_test_file> \
  --database=db18_test_<module_name> \
  --db_host=mydb \
  --db_user=odoo \
  --db_password=myodoo \
  --init=<module_name> \
  --update=<module_name>
```

All module tests:
```bash
/usr/bin/python3 /src/odoo/odoo-bin \
  --config=/etc/odoo/odoo.conf \
  --dev=all \
  --stop-after-init \
  --test-tags=/<module_name> \
  --database=db18_test_<module_name> \
  --db_host=mydb \
  --db_user=odoo \
  --db_password=myodoo \
  --init=<module_name> \
  --update=<module_name>
```

Replace `<module_name>` with the actual module technical name (e.g., `akaflieg_setup`).

## Test File Structure

Odoo tests must follow the OCA convention:
- Place test files in `<module>/tests/` directory
- Test files must be named `test_*.py`
- Test classes must extend `odoo.tests.common.TransactionCase` or similar
- The `tests/__init__.py` must import all test modules

Example test structure:
```
my_module/
├── tests/
│   ├── __init__.py    # imports test_my_module
│   └── test_my_module.py
```

## Debugging Test Failures

1. Check the test output in the VS Code Debug Console
2. Screenshots of failed UI tests are saved to `/src/screencasts/`
3. For database issues, use the pgAdmin web interface at http://localhost:8088
   - Username: `admin@odoo.com` / Password: `admin`
   - Database: `mydb` / User: `odoo` / Password: `myodoo`

## Related Skills

- `odoo-tests` — guidance on writing, structuring, and iterating on test code
