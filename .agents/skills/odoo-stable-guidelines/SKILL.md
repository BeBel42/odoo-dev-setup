---
name: odoo-stable-guidelines
description: >-
  Use this skill when working on a stable branch (e.g. 16.0, 17.0, saas-17.4).
  Covers the strict rules for what changes are allowed in stable series.
---

# Stable Branch Guidelines

These rules apply when working on **stable series** (released versions like 16.0, 17.0, saas-17.4). Stable patches must have a good value/risk ratio; if risk is too high or value too low, the change belongs in the development series (master), not stable.

## What Is NOT Allowed in Stable

### No Improvements
- No "improvements" (technical or functional): they have a very low value/risk ratio
- Often, functional coverage is voluntarily limited in stable

### No Cosmetic Changes
- No purely cosmetic changes (formatting, pep8, etc.)

### No Signature Changes
- No changes in the signature of **public methods** on models (methods not starting with `_`): they are part of the public API used by integrated systems
- Avoid changes in the signature of **private methods** as much as possible: they can be overridden in extension modules, which will break when the signature changes

### No Data Model Changes
- **Stored column definitions must not be altered** in incompatible manners under any circumstances
- No addition / removal / incompatible type change of stored columns
- Limited, compatible changes are allowed when necessary:
  - Changing `ondelete` rules
  - Changing `size` parameters
- For non-compatible changes: in extreme cases, an extra auto-install module could be added to automatically patch new installations without breaking existing ones

### No XML ID Changes
- No changes to the XML IDs of existing module data
- No deletion of module data records that may be referenced by user data in existing databases
- Exception: absolutely essential changes to records that were in `noupdate` mode initially

## What IS Allowed in Stable

### Bug Fixes
- Bug fixes with a good value/risk ratio
- It is fine if a bugfix requires an explicit update, as long as it is safe for users who are not aware of it and do not perform the update

### Limited Field Additions
- Non-stored function fields may be added if really necessary

### XML File Changes (with Restrictions)
- XML files (views, menus, default data, etc.) should only be changed if inevitable
- When changed, the change must not be mandatory: the Python code must not depend on the change

### Security Fixes
- **Critical security fixes must not depend on an explicit module update to take effect**
- They must work with a simple pull + restart

## Translation Considerations

Introducing new source terms (error messages, mail templates, view elements, etc.) should be reflected in the source terms of the module as explained in the translation documentation.
