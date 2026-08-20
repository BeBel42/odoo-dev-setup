---
name: odoo-project-layout
description: >-
  Use this skill to understand the Odoo workspace directory structure.
  Explains the four sibling repositories (community, enterprise, upgrade,
  upgrade-util) and how they relate to each other.
---

# Odoo Workspace Layout

This directory is a workspace holding several sibling Odoo repositories that are developed together, not a single project.

## The Four Repositories

### `community/`
**Odoo Community** — the framework plus community addons.

- `community/odoo/` — the core Odoo framework
- `community/addons/` — community addons (~675 modules)

### `enterprise/`
**Odoo Enterprise addons** — each top-level directory is one module.

- Depends on modules in `community/addons/`
- Requires `community/` to run
- Must be checked out at the same version as `community/`

### `upgrade/`
**Database migration scripts** — private, runs on top of `community/`.

- Layout: `upgrade/migrations/<module>/<version>/`
- Contains pre-migrate, post-migrate, and end-migrate scripts

### `upgrade-util/` (`odoo.upgrade.util`)
**Helper library** used by the scripts in `upgrade/`.

- Importable as `from odoo.upgrade import util`
- Located at `upgrade-util/src/util/`
- Groups helpers by concern: `fields.py`, `models.py`, `modules.py`, `records.py`, `pg.py`, `orm.py`, `inherit.py`, `domains.py`, `spreadsheet/`, etc.

## Version Synchronization

All four repositories are typically on `master` and kept in sync. When working with stable versions, `community` and `enterprise` must be checked out together at the same version.
