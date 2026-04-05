# Odoo Documentation Skill

Purpose: Generate and update concise module documentation for end users and administrators.

## When to Use

Use this skill when the task involves:
- Creating or updating `readme/` content
- Writing `DESCRIPTION.md`, `CONFIGURE.md`, `CONTRIBUTORS.md`, or `USAGE.md`
- Improving README content for a module
- Documenting configuration, menu paths, and operational behavior

## Documentation Scope

Focus on user-facing and administrator-facing documentation only.
Do not generate developer API docs or code comments.

When UI changes are part of the module update, documentation must also include updated screenshots with explicit visual callouts.

## Source Analysis

Before writing docs, inspect:
- `__manifest__.py` for module name, summary, version, dependencies
- `models/` for core business behavior
- `views/` for user-facing workflows and menu entries
- `security/` for groups and access prerequisites
- `data/` and `wizard/` for configurable behavior
- Existing `readme/` files to preserve useful content

## Expected Files

### `readme/DESCRIPTION.md`
Include:
- What the module does in 1-3 short paragraphs
- Key features
- Main business use cases

### `readme/CONFIGURE.md`

**Create this file only if configuration is actually required.**

Include only required setup:
- Settings or system parameters
- Security groups or permissions

**Do NOT create this file if there is no configuration needed.** Avoid placeholder statements like "No additional system parameters or security groups are required." If configuration is truly not needed, omit the file entirely.


### `readme/CONTRIBUTORS.md`
Use this format:
```markdown
- [Company Name](https://company.url)
  - Contributor Name <email@example.com>
```

### `readme/USAGE.md`
Create only if usage is not obvious from the standard Odoo UI.
Include short step-by-step instructions.

## UI Screenshot Requirements

When the module introduces or changes UI behavior (views, menus, buttons, labels, workflow states, or wizard steps):

- Include at least one screenshot whenever the module has at least one view xml file.
- Capture screenshots that show the changed UI states.
- Do not place any text labels inside the screenshot.
- Use markdown text for any explanatory wording, and keep it brief.
- Reference the screenshots from `readme/USAGE.md` or other relevant `readme/` files where the change is explained.
- Update existing screenshots instead of duplicating near-identical files when possible.

Recommended asset location:
- `readme/static/description/`

### Screenshot Capture Tips

To efficiently capture and generate screenshots:
- Use the GitHub test action workflow to spin up a running Odoo instance with your module installed
- Interact with the UI via the running instance to capture current state screenshots
- Automate screenshot collection via Selenium or similar tools if dealing with multiple UI states
- Store generated assets in the `readme/static/description/` directory before committing

## Quality Gate Before Commit

Before committing documentation changes, run pre-commit in the repository root:

```bash
pre-commit run --all-files
```

Do not commit until pre-commit passes or remaining failures are explicitly escalated.

## Documentation Principles

- Be concise and factual
- Prefer linking to existing authoritative docs over duplicating long explanations
- **Avoid placeholder text** — if a section has no meaningful content, omit the file entirely rather than creating dummy statements
- Avoid repeating obvious manifest metadata verbatim
- Write in Markdown only for `readme/` content
- Preserve existing useful docs and update them rather than replacing without reason
- Keep screenshot annotations minimal, clear, and focused on the migrated changes
- Keep documentation text short; avoid detailed UI-change narratives
- For UI screenshots, rely on concise image alt text for minimal context

## Output Expectations

After using this skill, provide:
- Files created or updated
- A short summary of the information documented
- Screenshot assets created or updated, including where layered highlights were applied
- Confirmation that at least one screenshot was added when view changes were present
- Confirmation that screenshot overlays contain no text and explanatory text is in markdown only
- Confirmation that `pre-commit run --all-files` was executed before commit and its result
- Any missing business details that still require human input
