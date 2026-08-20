---
name: odoo-upgrade-scripts
description: >-
  Use this skill when writing or understanding database migration scripts
  in the upgrade/ repository. Covers script phases, layout, and the util library.
---

# Odoo Upgrade Scripts

## Directory Layout

```
upgrade/migrations/<module>/<version>/<phase>-<name>.py
```

Where:
- `<module>` — the module being upgraded
- `<version>` — the module's target version string (e.g., `16.0.1.0`, `saas~18.1.1.4`)
- `<phase>` — one of `pre`, `post`, or `end`

## Script Phases

| Phase        | File Pattern      | When It Runs                                 |
|--------------|-------------------|----------------------------------------------|
| Pre-migrate  | `pre-migrate.py`  | Before the module's new data/schema is loaded|
| Post-migrate | `post-migrate.py` | After the module's data/schema is loaded     |
| End-migrate  | `end-migrate.py`  | At the very end of the whole upgrade         |

## Script Structure

Each script exposes `def migrate(cr, version):` and uses the util library:

```python
from odoo.upgrade import util

def migrate(cr, version):
    util.remove_view(cr, "website_customer.contact_edit_options")
```

## The Util Library (`upgrade-util`)

Located at `upgrade-util/src/util/`, the library groups helpers by concern:

| File           | Purpose                      |
|----------------|------------------------------|
| `fields.py`    | Field manipulation helpers   |
| `models.py`    | Model-related utilities      |
| `modules.py`   | Module management            |
| `records.py`   | Record manipulation          |
| `pg.py`        | Raw SQL/PostgreSQL helpers   |
| `orm.py`       | ORM-related utilities        |
| `inherit.py`   | Inheritance handling         |
| `domains.py`   | Domain manipulation          |
| `spreadsheet/` | Spreadsheet-specific helpers |

## Best Practice

**Reach for a `util` helper before writing raw SQL**: these functions are written to work across Odoo versions 7.0 to master.

Common util functions:
- `util.remove_view(cr, xmlid)` — remove a view
- `util.rename_field(cr, model, old, new)` — rename a field
- `util.rename_model(cr, old, new)` — rename a model
- `util.remove_field(cr, model, field)` — remove a field
- `util.column_exists(cr, table, column)` — check if column exists
- `util.table_exists(cr, table)` — check if table exists
