---
name: odoo-oca-submodule
description: Guide for adding OCA (Odoo Community Association) module repositories as git submodules. Use this when asked to add, include, or integrate OCA modules into a project.
---

# Adding OCA Modules as Git Submodules

This organization organizes OCA module repositories as git submodules within the project repository. Modules are stored under `modules/oca/` for OCA repositories and `modules/<org>/` for custom organization modules.

## Project Structure

```
project-repo/
├── .gitmodules
└── modules/
    ├── oca/
    │   ├── account-invoicing/    # OCA account-invoicing submodule
    │   ├── partner-contact/      # OCA partner-contact submodule
    │   └── ...
    └── c4a8/                     # Custom c4a8-odoo modules
        └── my-custom-module/
```

## Adding an OCA Module Submodule

To add an OCA module repository as a submodule:

```bash
# Navigate to the project root
cd /src/user

# Add OCA submodule (SSH - requires SSH key)
git submodule add -b 18.0 git@github.com:OCA/<repo-name>.git modules/oca/<repo-name>

# Or use HTTPS (no SSH key required)
git submodule add -b 18.0 https://github.com/OCA/<repo-name>.git modules/oca/<repo-name>
```

Example:
```bash
git submodule add -b 18.0 git@github.com:OCA/account-invoicing.git modules/oca/account-invoicing
```

## Available OCA Repositories

Common OCA repositories used by this organization:
- `OCA/account-invoicing` - Odoo Invoicing Extension Addons
- `OCA/partner-contact` - Odoo Partner and Contact related addons
- `OCA/sale-workflow` - Odoo Sales, Workflow and Organization
- `OCA/purchase-workflow` - Odoo Purchases, Workflow and Organization
- `OCA/server-tools` - Tools for Odoo Administrators
- `OCA/server-ux` - Server UX addons
- `OCA/server-backend` - Server Backend addons
- `OCA/crm` - Odoo CRM addons
- `OCA/project` - Odoo Project Management addons
- `OCA/social` - Odoo Social/Messaging addons
- `OCA/l10n-germany` - German localization addons

Browse all available OCA repositories at: https://github.com/OCA

## Initializing Submodules After Clone

After cloning the project repository, initialize all submodules:

```bash
git submodule update --init
git submodule update
```

## Updating a Submodule

To update a submodule to the latest commit on its tracked branch:

```bash
cd modules/oca/<repo-name>
git pull origin 18.0
cd ../..
git add modules/oca/<repo-name>
git commit -m "[UPD] Update <repo-name> submodule"
```

## Setting Up Pre-Commit for Submodules

Install pre-commit hooks in all OCA submodules:

```bash
git submodule foreach '[ "$(echo $path | grep -o "modules/oca")" ] && pre-commit install || true'
```

## Adding a Module to `odoo.conf`

After adding a submodule, add its path to the Odoo configuration (`/src/config/odoo.conf`):

```ini
[options]
addons_path = /src/odoo/addons,/src/odoo/odoo/addons,/src/user/modules/oca/account-invoicing,/src/user/modules/c4a8/my-module
```

## Finding the Right OCA Repository

To find the correct OCA repository for a specific Odoo module:

1. Search GitHub: `site:github.com OCA <module_name>`
2. Browse OCA repositories: https://github.com/OCA
3. Check the module name in `__manifest__.py` `depends` list and search for it

## Removing a Submodule

If you need to remove a submodule:

```bash
git submodule deinit modules/oca/<repo-name>
git rm modules/oca/<repo-name>
git commit -m "[REM] Remove <repo-name> submodule"
```
