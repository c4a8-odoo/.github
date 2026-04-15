---
name: odoo-coding
description: Version-aware Odoo coding syntax guide (16.0 through 19.0) with cumulative rules and no future-version assumptions.
---

# Odoo Coding Skill

Purpose: Guide the agent to write Odoo code using the correct syntax for a target version, with cumulative compatibility rules from earlier supported versions only.

## When to Use

Use this skill when the task involves:
- Writing or refactoring Python, XML, JS, manifests, or tests in Odoo modules
- Selecting version-correct syntax for 16.0, 17.0, 18.0, or 19.0
- Enforcing migration-safe coding style in new code edits

## Version Scope Policy

- Supported targets: 16.0, 17.0, 18.0, 19.0.
- Rules are cumulative by target version:
  - 16.0 target: apply 16.0 rules.
  - 17.0 target: apply 16.0 + 17.0 rules.
  - 18.0 target: apply 16.0 + 17.0 + 18.0 rules.
  - 19.0 target: apply 16.0 + 17.0 + 18.0 + 19.0 rules.
- Do not apply rules from versions greater than the target.
- Do not invent future rules beyond 19.0.

## How To Apply

1. Determine target Odoo version from branch/module context.
2. Load all rule sets up to that target version.
3. Output only modern syntax and when to use it.
4. Prefer minimal, local edits over broad refactors.
5. If a change depends on runtime semantics, mark for manual review.

## Cumulative Rule Sets

### 16.0 Rules (Base)

Python:
- Use `@api.model_create_multi` on `create()` overrides.
- Accept `vals_list` and keep per-record logic in a loop over created records and their values.
- Use `Command` helpers for x2many operations (`create`, `update`, `delete`, `unlink`, `link`, `clear`, `set`).
- Use recordset-scoped cache and flush APIs (`invalidate_recordset`, `flush_recordset`) and model-level invalidation when needed.

JavaScript:
- Use Odoo ESM modules with `/** @odoo-module **/` and native `import` / `export`.

Manifest and module metadata:
- Use manifest `assets` bundles for frontend/backend/report/qweb asset registration.
- Include a valid `license` key in the manifest.

Tests:
- Use `TransactionCase` as the standard base test class for 16.0-compatible tests.
- Prefer `setUpClass` for shared fixtures where safe.

XML and data:
- For `mail.activity.type` records, use `res_model` with the model technical name.

### 17.0 Additions (Applied on top of 16.0)

XML view expressions:
- Use inline Python expressions directly on view attributes:
  - `invisible="..."`
  - `readonly="..."`
  - `required="..."`
- Keep these expressions explicit and readable for state-based behavior.

Python models and hooks:
- Keep field definitions free of state-behavior toggles; put UI state logic in XML expressions.
- Use hook signatures that receive `env`.
- Use zero-argument `super()` calls.
- Keep `create()` overrides in multi-create style.

Messaging and ORM:
- Call `message_post()` with supported 17.0 keyword arguments only.
- Use `_read_group(domain, groupby, aggregates)` for grouped backend aggregations.

Tests:
- Use `BaseCommon` when its standard fixtures match the test needs.

Documentation and packaging:
- Keep readme fragment files in Markdown.
- Keep module packaging metadata aligned with OCA 17.0 conventions.

### 18.0 Additions (Applied on top of 16.0 + 17.0)

XML views and actions:
- Use `<list>` in view arch definitions.
- Use `view_mode` values with `list` for list-style actions.
- Use `<chatter />` for standard chatter section embedding.
- In `ir.actions.act_window` context strings, use `active_id` when referencing the active record id.
- For `res.config.settings` views, use `<block>` and `<setting>` structure.

Python API and fields:
- Use `self.env._("...")` for translations.
- Use `has_access("perm")` for non-raising access checks.
- Use product typing with `type` and `is_storable` semantics.
- Override `search()` with `@api.readonly` and `@api.returns('self')` where readonly search customization is needed.
- Keep method signatures aligned with 18.0 APIs for procurement and carrier extension points.
- Use `zip(..., strict=False)` in parallel iteration patterns over records and value lists.

Manifest and dependencies:
- Use `delivery` dependency naming where 18.0 modules require it.

Tests:
- Import `Form` from `odoo.tests`.
- Use direct picking completion flows in tests when no interactive wizard path is under test.

### 19.0 Additions (Applied on top of 16.0 + 17.0 + 18.0)

HTTP and request handling:
- Use route declarations with `type="jsonrpc"` for JSON-RPC endpoints.

Environment access:
- Use `self.env.cr` for cursor access.
- Use `self.env.context` for contextual values.
- Use `self.env.uid` for numeric user id usage.
- Use `self.env.user` when record semantics are required.

Domain and grouped query APIs:
- Use `Domain` imports from `odoo.fields` for domain composition helpers.
- Use `Domain.AND(...)` and `Domain.OR(...)` for composed domain logic.
- Use `_read_group(...)` in backend code and handle its result structure correctly.

Model constraints and lifecycle hooks:
- Define SQL constraints with class-level `models.Constraint` attributes.
- Use `@api.ondelete(at_uninstall=False)` for delete validation guards.

Field and search semantics:
- Use `group_ids` where the 19.0 schema expects it.
- Use explicit archive actions (`action_archive`, `action_unarchive`) for active-state transitions.
- Use `bypass_search_access=` field parameter where search-access bypass behavior is intended.

XML search views:
- Keep `<search><group>` clean without unsupported presentation attributes.

Timezone and caching:
- Use `self.env.tz` for effective timezone resolution.
- Use `@tools.ormcache(...)` with explicit cache-key inputs when context-sensitive behavior is needed.

## Output Contract For The Agent

When this skill is used, respond with:
- Target version detected
- Rule tiers applied (for example: 16.0 + 17.0 + 18.0 + 19.0)
- Files changed
- Manual-review spots, if any
- Short rationale per non-trivial syntax decision

## Guardrails

- Only emit syntax valid for the selected target version.
- Never include recommendations for versions newer than the target.
- Keep guidance in terms of modern syntax and usage intent.
- Avoid unrelated architectural rewrites during syntax updates.
