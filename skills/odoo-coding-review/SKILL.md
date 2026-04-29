---
name: odoo-coding-review
description: Odoo coding review guide for syntax, rules and best practices.
---

# Odoo Coding Review Skill

Purpose: Check and refactor Odoo code using the correct syntax for a target version, with cumulative compatibility rules from earlier supported versions only.

## When to Use

Use this skill when the task involves:
- Writing or refactoring Python, XML, JS, manifests, or tests in Odoo modules
- Reviewing module to ensure it follows version-correct latest syntax

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

1. Determine target Odoo version from __manifest__.py of the module.
2. Determine which kind of rules are relevant for the code under review (Python, XML, JS, manifest, tests).
3. Load all needed rule sets up to that target version.
4. Output only modern syntax and when to use it.
5. Prefer minimal, local edits over broad refactors.

## Cumulative Rule Sets

Always apply the base rules of resource @resources/code-rules.yaml. Also apply all rules of the resources, below the target version.

### 19.0 Additions
- Use rules from @resources/odoo-coding-rules-19.0.yaml
- 18.0 Additions

### 18.0 Additions
- Use rules from @resources/odoo-coding-rules-18.0.yaml
- 17.0 Additions

### 17.0 Additions 
- Use rules from @resources/odoo-coding-rules-17.0.yaml
- 16.0 Additions

### 16.0 Additions 
- Use rules from @resources/odoo-coding-rules-16.0.yaml

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
