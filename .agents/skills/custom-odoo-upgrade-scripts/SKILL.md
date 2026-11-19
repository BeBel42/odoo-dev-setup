---
name: custom-odoo-upgrade-script
description: Load this when creating Odoo upgrade scripts
---
# HR upgrade scripts: one script per PR

To avoid merge conflicts between open upgrade PRs, never add code to the shared `pre-migrate.py`, `post-migrate.py` or `end-migrate.py` in a version folder.
Leave existing ones as they are; this applies to new work only.

Instead, add a new file in the same version folder named after the upgrade PR number:
`pre-pr-<number>.py`, `post-pr-<number>.py` or `end-pr-<number>.py`.
```
l10n_be_hr_payroll/saas~20.1.1.0/
    pre-migrate.py   # existing, don't touch
    pre-pr-9123.py   # PR 9123
    post-pr-9140.py  # PR 9140
```

- **Naming:** The PR number only exists once the PR is open. If it's unknown, use a clear placeholder and remind the user to rename the file after opening the PR.
- **Order:** Scripts in one phase run in alphabetical order: `pre-migrate.py` first, then `pre-pr-*` by PR number. Each script must work on its own. If it depends on another open PR's script, then put both scripts in one PR.
- **Tests:** Put each upgrade test in its own `tests/test_<topic>.py`; the only shared edit is one import line in `tests/__init__.py`.
- Don't fold `*-pr-*.py` files into `*-migrate.py` unless explicitly asked.

