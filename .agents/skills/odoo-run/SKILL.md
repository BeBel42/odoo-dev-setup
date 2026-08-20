---
name: odoo-run
description: >-
  Use this skill when you need to run Odoo, execute tests, manage the database,
  or perform any container operation. Covers the ./o wrapper script for Docker.
---

# Running Odoo with the `./o` Script

All Odoo operations go through the `./o` script, located at the root of the workspace. It wraps Docker: Odoo runs inside containers, never on the host.

## IMPORTANT: Always Consult `./o --help`

**The `./o --help` output is the authoritative reference.** It contains comprehensive documentation for every flag and common usage patterns. When in doubt, run:

```bash
./o --help
```

Or use `scripts/get-help.sh` in this skill directory to get the complete output.

**Do not guess flags or options.** The help text is extensive and covers edge cases not listed in this summary.

---

## Key Facts

- **Every run stops and recreates containers**: use `--no-restart` to `docker exec` into running ones instead
- **Blocking by default**: a plain run attaches to the container and blocks until it exits
  - Non-blocking cases: `-t/--test`, `--init-only`, and operations that don't launch Odoo (checkout, pull, `--db-list`, etc.)
  - **Never launch a blocking run in the foreground of an unattended shell**
- **Module selection**: `-m <module_list>` (comma-separated)
  - `-d` drops the database first
  - `-i` installs modules
  - `-u` upgrades modules

## Common Recipes

```bash
# run all tests of a module
./o -m hr_attendance -t /hr_attendance

# run a single test method
./o -m hr_attendance -t :TestHrAttendanceManager.test_employee_attendance_smart_button

# fresh db + install a module, then stop (non-blocking)
./o -m hr_attendance -d -i --init-only

# drop db and refill it from a saved template (fast reset)
./o --template my_template

# open a python shell / bash inside the odoo container
./o --shell
./o -b
```

These are just highlights. **Consult `./o --help` for the full list of options.**
