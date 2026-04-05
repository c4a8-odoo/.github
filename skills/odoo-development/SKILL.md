# Odoo Development Skill

Purpose: Scaffold and extend Odoo modules in an OCA-compliant way for this workspace.

## When to Use

Use this skill when the task involves:
- Creating a new addon or extending an existing module
- Adding models, fields, views, security, data, or wizards
- Setting up module structure in the correct repository
- Aligning implementation with OCA and c4a8 conventions

## Workspace Rules

- Community custom addons go in `/src/user/modules/c4a8/community/`
- Enterprise-only addons go in `/src/user/modules/c4a8/enterprise/`
- Customer/project-specific addons go in `/src/user/modules/c4a8/custom/`
- Prefer OCA conventions for Odoo 18.0
- Query the live Odoo schema over JSON-RPC when field/model details matter

## Standard Module Structure

```text
my_module/
├── __manifest__.py
├── __init__.py
├── models/
├── views/
├── security/
├── data/
├── static/
├── tests/
├── readme/
├── hooks.py          # only when pre/post_init_hook or uninstall_hook is used
└── exceptions.py     # only when custom exceptions are defined
```

Use `odoo-module-scaffold` when creating a new module from scratch.

## Development Rules

- Version format: `18.0.x.y.z`, start with `18.0.1.0.0`
- License for c4a8 community modules: `AGPL-3`
- Author: `"glueckkanja AG, Odoo Community Association (OCA)"` — OCA requires the suffix
- Module names: use **singular** form (e.g., `sale_order_discount`, not `sale_orders_discount`); prefix with the extended module's name when extending (e.g., `mail_forward`)
- Website: `https://github.com/c4a8-odoo/<repo-name>` (use the actual repo name)
- Use `<list>` instead of `<tree>` in XML views
- Do not add `string=` when the default label is sufficient
- Use `self.env._("...")` for translatable strings
- Use `<chatter />` instead of legacy chatter markup
- Prefer Python expressions over `attrs` / `states`
- Place installation hooks (`pre_init_hook`, `post_init_hook`, `uninstall_hook`) in `hooks.py`, never inline in `__manifest__.py`

## Implementation Guidance

### Models
- Group fields logically with short section comments when it improves readability
- Always define `comodel_name` for relational fields
- Add `ondelete` and `help` for non-trivial relations
- Add `index=True` on fields commonly used in searches and filters
- Use explicit nested dependencies in `@api.depends`

### Views
- Keep view definitions minimal and OCA-style
- Prefer clear form/list/search layouts over custom complexity
- Use `groups` on elements rather than broad view-level restrictions when needed

### Security
- Add `security/ir.model.access.csv` for every new model
- Create explicit groups when roles differ materially
- Load security files before business data in the manifest

### Delegation Boundaries
- New module scaffolding belongs to the `odoo-module-scaffold` skill
- Substantive tests belong to the `odoo-tests` skill
- Substantive readme/docs belong to the `odoo-documentation` skill
- Migration work belongs to the `odoo-migrate-module` skill
- Final compliance checks belong to the `odoo-validate-module` skill

## Recommended Workflow

1. Determine the correct repository and module path.
2. Inspect neighboring modules for style and patterns.
3. If needed, query live schema via JSON-RPC.
4. Create or update manifest, models, views, security, and data.
5. Hand off to tests and documentation skills for deeper work.
6. Run validation before considering the module ready.

## Output Expectations

After using this skill, provide:
- Files created or changed
- Module structure added or extended
- Any assumptions made about models, business rules, or dependencies
- Follow-up steps for tests, documentation, and validation
