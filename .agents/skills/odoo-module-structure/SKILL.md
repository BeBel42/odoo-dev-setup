---
name: odoo-module-structure
description: >-
  Use this skill when creating or understanding an Odoo addon module.
  Covers the directory layout, __manifest__.py, and common subdirectories.
---

# Odoo Addon Module Structure

An Odoo module is a directory containing a `__manifest__.py` file with metadata.

## The Manifest (`__manifest__.py`)

Key fields:
- `name` — human-readable module name
- `version` — module version string
- `depends` — list of module dependencies
- `data` — list of XML/CSV files to load (order matters!)
- `category` — module category for grouping

Example:
```python
{
    'name': 'My Module',
    'version': '1.0',
    'depends': ['base', 'mail'],
    'data': [
        'security/ir.model.access.csv',
        'views/my_model_views.xml',
        'data/demo_data.xml',
    ],
    'category': 'Sales',
}
```

## Common Subdirectories

| Directory      | Purpose                             |
|----------------|-------------------------------------|
| `models/`      | Python ORM model definitions        |
| `views/`       | XML view definitions                |
| `data/`        | Static data files (XML/CSV)         |
| `security/`    | Access rules, `ir.model.access.csv` |
| `wizard/`      | Transient models (wizards)          |
| `controllers/` | HTTP routes                         |
| `static/`      | JS/CSS/OWL frontend assets          |
| `report/`      | Report templates                    |
| `tests/`       | Python test files                   |
| `i18n/`        | Translation files                   |

## Important Notes

- **Data file order matters**: files in the `data` list load in listed order. Ordering is critical when records reference each other.
- Each subdirectory typically has an `__init__.py` that imports its Python modules.
- The module's root `__init__.py` imports from subdirectories (e.g., `from . import models, controllers`).
