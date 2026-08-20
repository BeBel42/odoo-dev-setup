---
name: odoo-git-conventions
description: >-
  Use this skill when making commits, naming branches, or understanding
  Odoo's versioning policy. Covers commit message format and branch naming.
---

# Odoo Conventions

## Commit Message Format

```
[TAG] module: short description
```

### Tags

| Tag   | Meaning                          |
|-------|----------------------------------|
| `FIX` | Bug fix                          |
| `IMP` | Improvement to existing feature  |
| `ADD` | New feature                      |
| `REF` | Refactoring (no behavior change) |
| `REM` | Removal of code/feature          |
| `MOV` | Moving code between modules      |

### Examples

```
[FIX] sale: correct discount calculation on multi-line orders
[IMP] stock: optimize inventory valuation query
[ADD] hr_attendance: add overtime tracking feature
[REF] account: split large method into smaller helpers
[REM] website_sale: remove deprecated payment provider
[MOV] mail: move template rendering to mail_render
```

## Feature Branch Naming

```
<base>-<module>-<description>-<quadrigram>
```

- `<base>`: the target branch (e.g., `master`, `17.0`)
- `<module>`: the modified module(s) (e.g.: `l10n_be_hr_payroll`, `l10n_*_hr_payroll`)
- `<description>`: short snake_case description
- `<quadrigram>`: your 4-letter identifier

### Examples

```
master-crm-fix_private_sign_requests-mlef
17.0-hr_payroll-add_overtime_tracking-mlef
saas-18.1-l10n_*_hr_payroll-refactor_invoice_flow-mlef
```

Note: This convention is common but not strictly enforced; do not block on it.

## Versioning Policy

- **Stable series** (released versions like 16.0, 17.0) only accept restricted changes:
  - Bug fixes
  - No schema or behavior breaks
- **New features** target `master` only
