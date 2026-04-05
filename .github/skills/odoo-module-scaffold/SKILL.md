---
name: odoo-module-scaffold
description: Guide for creating a new Odoo module following OCA standards. Use this when asked to create, scaffold, or initialize a new Odoo module or addon.
---

# Creating a New Odoo Module (OCA Standards)

This organization uses the OCA (Odoo Community Association) `oca-addons-repo-template` via Copier to scaffold new module repositories.

## Prerequisites

- [Copier](https://copier.readthedocs.io/) installed: `pip install copier`
- Access to the parent repository where modules are stored

## Scaffolding a New Module Repository

Use the OCA copier template to create a new module repository:

```bash
copier copy gh:oca/oca-addons-repo-template /path/to/new-module-repo
```

Answer the prompts:
- `odoo_version`: e.g., `18.0`
- `org_name`: `c4a8-odoo`
- `repo_name`: e.g., `my-new-module`
- `repo_description`: Description of the module

## Module Directory Structure

Each Odoo module follows this standard OCA structure:

```
my_module/
├── __init__.py
├── __manifest__.py
├── models/
│   ├── __init__.py
│   └── my_model.py
├── views/
│   └── my_model_views.xml
├── security/
│   └── ir.model.access.csv
├── tests/
│   ├── __init__.py
│   └── test_my_module.py
├── static/
│   └── description/
│       └── icon.png
└── README.rst
```

## Manifest File (`__manifest__.py`)

```python
# Copyright <year> <Author>
# License AGPL-3.0 or later (https://www.gnu.org/licenses/agpl).

{
    "name": "My Module Name",
    "summary": "Short description of what the module does",
    "version": "18.0.1.0.0",
    "license": "AGPL-3",
    "category": "Category",
    "author": "c4a8-odoo",
    "website": "https://github.com/c4a8-odoo/module-repo",
    "depends": ["base"],
    "data": [
        "security/ir.model.access.csv",
        "views/my_model_views.xml",
    ],
}
```

Version format: `<odoo_version>.<major>.<minor>.<patch>` (e.g., `18.0.1.0.0`)

## Model File (`models/my_model.py`)

```python
# Copyright <year> <Author>
# License AGPL-3.0 or later (https://www.gnu.org/licenses/agpl).

from odoo import fields, models


class MyModel(models.Model):
    _name = "my.model"
    _description = "My Model"

    name = fields.Char(string="Name", required=True)
```

## Code Quality

Before committing, install and run pre-commit hooks:

```bash
cd /path/to/module-repo
pre-commit install
pre-commit run --all-files
```

The pre-commit configuration includes:
- **black**: Python code formatting
- **isort**: Python import sorting
- **flake8**: Python linting
- **pylint-odoo**: Odoo-specific linting
- **prettier**: XML/JS/CSS formatting
- **oca-checks-odoo-module**: OCA module checks

## Adding the Module to the Project

Add the module to the project's git submodules (see `odoo-oca-submodule` skill):

```bash
git submodule add -b 18.0 git@github.com:c4a8-odoo/my-new-module.git modules/c4a8/my-new-module
```
