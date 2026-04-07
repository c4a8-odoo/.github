# Odoo Validate Module Skill

**Purpose:** Validate Odoo modules against OCA best practices, c4a8 conventions, and team patterns. Produces a structured report with errors, warnings, and actionable fixes.

---

## Overview

The `odoo-validate-module` skill performs a comprehensive audit of an Odoo module to ensure it:
- ✅ Follows OCA coding conventions
- ✅ Complies with c4a8 team standards
- ✅ Has adequate test coverage
- ✅ Meets security best practices
- ✅ Is mergeable to main

---

## How to Use

### Basic Validation
```
@odoo /validate-module
```
Validates the current module (auto-detected from file path).

### Validate Specific Module
```
@odoo /validate-module equipment_confirmation
```

### Validate Multiple Modules
```
@odoo /validate-module equipment_confirmation hr_expense_addon
```

### In Conversation
```
@odoo Check if the equipment_confirmation module follows OCA best practices
```

The skill validates, produces a report, and suggests fixes for any issues found.

---

## Validation Checks

### 1. Manifest Structure (`__manifest__.py`)

**Checks performed:**
- ✅ File exists and is valid Python
- ✅ Required fields present: `name`, `version`, `author`, `license`, `category`, `website`
- ✅ `version` format matches `18.0.x.y.z` (major.minor.patch)
- ✅ `license` is `"AGPL-3"` (OCA standard)
- ✅ `author` contains `, Odoo Community Association (OCA)` (OCA requirement)
- ✅ `website` is `"https://github.com/c4a8-odoo/<repo-name>"` (c4a8 standard)
- ✅ Module technical name uses singular form and follows OCA naming conventions
- ✅ `depends` list is non-empty and valid module references exist
- ✅ `data` and `demo` lists use valid file paths
- ✅ No orphaned or circular dependencies
- ✅ `installable` is `True` (unless intentionally marked `False`)

**Example Error:**
```
❌ MANIFEST FIELD MISSING: version
   Expected format: 18.0.x.y.z (e.g., 18.0.1.0.0)
   File: equipment_confirmation/__manifest__.py
```

**Example Warning:**
```
⚠️ MANIFEST FIELD VALUE: website
   Current: "https://github.com/user/repo"
   Expected: "https://github.com/c4a8-odoo/module-c4a8-community"
   File: equipment_confirmation/__manifest__.py
```

```
⚠️ MANIFEST FIELD VALUE: author
   Current: "c4a8-odoo"
   Expected: "c4a8-odoo, Odoo Community Association (OCA)"
   File: equipment_confirmation/__manifest__.py
```

---

### 2. OCA Conventions

#### Field Definitions
- ✅ All relational fields (Many2one, One2many, Many2many) have `comodel_name`
- ✅ Relational fields have `string` unless default matches field name
- ✅ Relational fields have `ondelete` behavior specified
- ✅ Fields have `help` text for complex/non-obvious fields
- ✅ Search-heavy fields (partner_id, employee_id, user_id) have `index=True`
- ✅ Float fields use `odoo.tools.float_is_zero()` for comparisons (detected in tests/code)
- ✅ No hardcoded translatable strings — use `self.env._("...")`

**Example Error:**
```
❌ FIELD DEFINITION INCOMPLETE: models/equipment.py:45
   Field: partner_id (Many2one)
   Missing: comodel_name, ondelete
   Relational fields require: comodel_name, string, ondelete, help
```

#### Model Inheritance
- ✅ Functional bases listed before mixins (e.g., `models.Model`, then `mail.thread`, `mail.activity.mixin`)
- ✅ Docstrings on models and inherited models
- ✅ Computed fields have `@api.depends()` with explicit paths (e.g., `line_ids.amount`, not just `line_ids`)
- ✅ Inverse and compute methods properly paired

**Example Warning:**
```
⚠️ API DEPENDS PATH: models/equipment.py:120
   Method: _compute_next_date
   Current depends: @api.depends('confirmation_date')
   Suggestion: Add nested paths if you access related fields:
              @api.depends('confirmation_date', 'employee_id.company_id')
```

---

### 3. Test Coverage

**Checks performed:**
- ✅ `tests/` directory exists
- ✅ `tests/__init__.py` exists and imports test classes
- ✅ At least one `test_*.py` file per module
- ✅ Test classes inherit from `TransactionCase` or domain-specific base
- ✅ Test methods start with `test_`
- ✅ Test methods have docstrings
- ✅ setUp/setUpClass methods exist with reasonable test data
- ✅ Key workflows are tested (create, write, action methods)

**Coverage targets:**
- Models: ≥ 70% coverage of public methods
- Views/XML: All major views have at least one test

**Example Error:**
```
❌ TEST COVERAGE MISSING: equipment_confirmation
   Status: No tests found
   Expected: tests/test_equipment_*.py files
   Suggestion: Write tests for:
     - Equipment confirmation flows
     - Activity creation
     - State transitions
     - Permission checks
```

**Example Warning:**
```
⚠️ TEST COVERAGE LOW: equipment_confirmation
   Status: 2 test methods × 1 test file = 35% coverage
   Critical untested areas:
     - Equipment annual confirmation wizard
     - Email notification flows
     - Cron job triggers
```

---

### 4. Security Rules

**Checks performed:**
- ✅ `security/ir.model.access.csv` exists
- ✅ All models have access rules defined
- ✅ Security groups exist and are meaningful (not overly broad)
- ✅ Access rules use appropriate groups
- ✅ Record-level security (ir.rule) exists for sensitive operations
- ✅ Group definitions in XML files match ir.model.access.csv

**Example Error:**
```
❌ SECURITY ACCESS MISSING: maintenance.equipment
   File: security/ir.model.access.csv
   Expected: Access rules for group_equipment_user, group_equipment_manager
   Current: No rules defined
```

**Example Warning:**
```
⚠️ SECURITY GROUP MISSING: security/equipment_security.xml
   Group: equipment_manager
   Issue: Group defined in manifest data but not in XML
   Suggestion: Create security/equipment_security.xml with <record> for group_equipment_manager
```

---

### 5. XML Views

**Checks performed:**
- ✅ View files use `<list>` tag, not `<tree>` (OCA 18.0 convention)
- ✅ Field tags are properly closed
- ✅ No hardcoded strings in views (use `groups` attribute for labels)
- ✅ View names follow convention: `module.model_view_type` (e.g., `equipment_confirmation.maintenance_equipment_list`)
- ✅ Search views include sensible default filters
- ✅ Form views use proper field grouping and invisible attributes
- ✅ No deprecated Odoo attributes

**Example Error:**
```
❌ VIEW TAG INCORRECT: views/equipment_views.xml:15
   Line: <tree string="Equipment List">
   Issue: OCA 18.0 convention uses <list>, not <tree>
   Fix: Change <tree> to <list>
```

**Example Warning:**
```
⚠️ VIEW HARDCODED STRING: views/equipment_views.xml:42
   Line: <field name="state" string="Status" />
   Issue: string attribute hardcoded; breaks translation
   Fix: Remove string attribute. ORM infers label from field name.
        Or: <field name="state" string="Current Status" /> with translation
```

---

### 6. Code Quality

**Checks performed:**
- ✅ Ruff lint passes (no syntax/style errors)
  - Line length 160 (c4a8 standard)
  - Import order: future, stdlib, third-party, odoo, odoo-addons, first-party, local
  - No unused imports
  - No undefined variables
- ✅ No hardcoded database IDs or paths
- ✅ Naming conventions: snake_case for methods/fields, PascalCase for classes
- ✅ Method/function docstrings exist for public APIs
- ✅ No deprecated Odoo APIs

**Example Error:**
```
❌ RUFF LINT FAILURE: models/equipment.py:67
   Error: E501 line too long (185 > 160)
   Line: self.env['mail.activity'].create({'user_id': user.id, 'activity_type': ...}
   Fix: Break line into multiple statements or use line continuations
```

**Example Warning:**
```
⚠️ CODE QUALITY: models/equipment.py:150
   Pattern: Using == for float comparison
   Current: if equipment.age == 1.0:
   Suggested: from odoo.tools import float_is_zero
              if float_is_zero(equipment.age - 1.0, precision_digits=2):
   Reference: /memories/repo/odoo-patterns.md → "Float comparisons"
```

---

### 7. Module Structure & Documentation

**Checks performed:**
- ✅ README.rst or readme/ directory exists
- ✅ readme/DESCRIPTION.md exists with module overview
- ✅ readme/CONFIGURE.md exists with configuration instructions (if applicable)
- ✅ readme/CONTRIBUTORS.md exists with author info
- ✅ `__init__.py` properly imports models, wizards
- ✅ Data files ordered: security → data → demo
- ✅ No unnecessary comments or dead code

**Example Warning:**
```
⚠️ DOCUMENTATION INCOMPLETE: equipment_confirmation
   Missing: readme/CONFIGURE.md
   Expected: Configuration instructions for ir.config_parameter settings
             Security group setup, etc.
```

---

### 8. Team Patterns Compliance

**Checks performed:**
- ✅ Code matches patterns in `/memories/repo/odoo-patterns.md`
  - Test patterns (Command API, setUp, TransactionCase)
  - Field definition patterns (index, depends, tracking)
  - Code quality patterns (float_is_zero, NULL handling)
  - Gotchas are avoided (test DB naming, context injection)

**Example Info:**
```
ℹ️ PATTERN MATCH: models/equipment.py:200
   Pattern: "test data using @classmethod setUpClass"
   Status: ✅ Compliant — Your test uses class-level setup correctly
```

**Example Warning:**
```
⚠️ PATTERN MISMATCH: tests/test_equipment.py:88
   Pattern: "use Command.create() for m2m operations"
   Current: self.equipment.employee_ids = [cmd0_id, cmd1_id]
   Suggested: self.equipment.employee_ids = Command.set([cmd0_id, cmd1_id])
   Reference: /memories/repo/odoo-patterns.md → "Command API for collections"
```

---

## Report Format

### Example Output

```
=================================================================
        VALIDATION REPORT: equipment_confirmation
=================================================================

✅ MANIFEST STRUCTURE (7/7 checks passed)
   ✓ Required fields present
   ✓ Version format: 18.0.1.0.0 (valid)
   ✓ License: AGPL-3
   ✓ Website: https://github.com/c4a8-odoo/module-c4a8-community
   ✓ Dependencies resolved
   ✓ Data files valid
   ✓ No circular dependencies

✅ OCA CONVENTIONS (12/13 checks passed)
   ✓ Field definitions include comodel_name, ondelete
   ✓ Model docstrings present
   ✓ Computed field @api.depends paths explicit
   ⚠️ WARNING: Field 'employee_id' missing `index=True` (line 45)
             Suggestion: Add index=True for list view filtering

✅ TEST COVERAGE (4/5 checks passed)
   ✓ tests/ directory exists
   ✓ Test classes inherit from TransactionCase
   ✓ Test methods have docstrings
   ✓ 2 test files with 8 test methods
   ⚠️ WARNING: Coverage 65% — recommend testing annual confirmation wizard

✅ SECURITY RULES (5/5 checks passed)
   ✓ ir.model.access.csv defined
   ✓ All models have rules
   ✓ Security groups meaningful
   ✓ Record-level rules for sensitive operations

✅ XML VIEWS (6/6 checks passed)
   ✓ Using <list>, not <tree>
   ✓ No hardcoded strings
   ✓ Proper field grouping
   ✓ All views named correctly

⚠️ CODE QUALITY (9/10 checks passed)
   ✓ Ruff lint: No errors
   ✓ Import order correct
   ⚠️ WARNING: Line 150 — float comparison without float_is_zero()
              Pattern reference: /memories/repo/odoo-patterns.md

✅ DOCUMENTATION (3/3 checks passed)
   ✓ README.rst exists
   ✓ DESCRIPTION.md complete
   ✓ CONFIGURE.md present

✅ TEAM PATTERNS (8/8 checks matched)
   ✓ Test setup patterns followed
   ✓ Field patterns aligned
   ✓ String NULL handling correct
   ✓ Context injection proper

=================================================================
SUMMARY
=================================================================
✅ READY FOR MERGE
   - 7 categories fully passed
   - 2 minor warnings found (easily fixable)
   - Estimated time to fix: 10 minutes
   - No blockers

WARNINGS TO ADDRESS (Before merge):
   1. Add index=True to employee_id field (models/equipment.py:45)
   2. Use float_is_zero() for float comparison (models/equipment.py:150)

SUGGESTIONS (Nice to have):
   - Expand test coverage for annual confirmation wizard
```

---

## How to Fix Issues

### By Severity

**❌ ERRORS** (Must fix before merge)
- Fix manifest errors (missing fields, version format)
- Add missing security rules
- Fix XML view syntax
- Resolve ruff lint failures

**⚠️ WARNINGS** (Should fix, reviewable as-is)
- Add missing docstrings
- Improve test coverage
- Follow team patterns
- Optimize field definitions

**ℹ️ INFO** (Educational, no action required)
- Pattern matches
- Best practice references

### Suggested Workflow

```bash
# 1. Validate module
@odoo /validate-module my_module

# 2. Fix errors in order (manifest → security → models → tests)
# Use IDE to make changes

# 3. Re-validate
@odoo /validate-module my_module

# 4. Address warnings
# Reference /memories/repo/odoo-patterns.md for guidance

# 5. Final check
@odoo /validate-module my_module
# → READY FOR MERGE ✅
```

---

## Integration with @odoo Agent

The `@odoo` agent:
- **Auto-validates** modules when creating/migrating to ensure compliance
- **References patterns** from `/memories/repo/odoo-patterns.md` during code generation
- **Suggests fixes** based on validation report
- **Blocks merge** if critical errors found (can be overridden with `--force-merge`)

If validation fails during module creation:
```
@odoo Create a new equipment_tracking module
[Agent creates module structure]
[Validation runs automatically]
⚠️ WARNING: Test coverage 0% — recommend writing initial tests
✅ Module created successfully (warnings only, not blocking)
```

---

## Advanced Usage

### Validation with Auto-Fix
```
@odoo /validate-module equipment_confirmation --auto-fix
```
Automatically fixes safe issues like:
- Ruff formatting (imports, line length)
- Add missing docstring stubs
- Fix view tag syntax

### Strict Mode (No Warnings)
```
@odoo /validate-module equipment_confirmation --strict
```
Fails if any warnings found (useful for CI/CD pipelines).

### Compare to Patterns
```
@odoo /validate-module equipment_confirmation --patterns-only
```
Only checks compliance with team patterns in `/memories/repo/odoo-patterns.md`.

---

## Configuration

**Validation level** can be set in [copilot-instructions.md](.github/copilot-instructions.md):

```yaml
# Standard (default)
validation_level: standard
# → Catches errors + warnings

# Strict
validation_level: strict
# → Errors only, fails on warnings

# Lenient
validation_level: lenient
# → Errors only, warnings are informational
```

---

## Related Skills

| Skill | Integration |
|-------|-------------|
| `odoo-development` | Validates module after creation |
| `odoo-tests` | Reports test coverage via validation |
| `odoo-migrate-module` | Validates module after migration |
| `odoo-remember-feedback` | Validation patterns stored in `/memories/repo/odoo-patterns.md` |

---

## FAQ

**Q: Can I skip validation?**  
A: Yes, but not recommended. Use `@odoo create-module --no-validate` to skip, but validation before merge is still required.

**Q: How often should I validate?**  
A: After significant changes — especially after writing models, tests, or security rules. Use `/validate-module` as part of your development workflow.

**Q: Can I add custom validation rules?**  
A: Yes, through `@odoo /remember-pattern "custom rule..."`. Custom rules are stored in `/memories/repo/odoo-patterns.md` and validated against.

**Q: What if validation contradicts OCA standards?**  
A: OCA standards always take priority. If team patterns conflict with OCA, update `/memories/repo/odoo-patterns.md` or file an issue.

**Q: Can AI auto-fix all issues?**  
A: No, only safe, deterministic fixes. Manual fixes required for:
  - Business logic errors
  - Test method implementation
  - Documentation content
  - Complex refactoring
