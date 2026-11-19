---
name: custom-odoo-write-test
description: Use this skill when writing an Odoo test (not an upgrade test)
---

# Writing Odoo tests

## Asserts
**Assert messages**
- Every assert takes a message explaining why it failed.
- The message states the context, e.g. "The employee's seniority must increase when the contract is extended".
- Prefer f-strings over using `%` for assert messages.

**Expected values**
Compute them logically instead of hardcoding. If an employee works 8 hours a day and 3 working days are expected, don't write:
```python
self.assertEqual(var.worked_hours, 24, "3 working days should be counted if the employee resigns after 3 days")
```
but rather:
```python
work_hours_per_day = employee.resource_calendar_id.hours_per_day
self.assertEqual(var.worked_hours, work_hours_per_day * 3, "3 working days should be counted if the employee resigns after 3 days")
```

## Test docstrings
- Test docstrings must explain concisely what the test is trying to do. It's purpose.
e.g.:
```python
def test_copy_submitted_request(self):
    """
    When duplicating an approval request, the copy should have everything
    copied (products, approvers, etc.), but, its approval state should be
    reset to "To Submit" ('new')
    """
```
- Always put the `"""` on their own line. Don't do `""" test docstring """`.
- Start the docstring with a captial letter. No need for a period at the end.
