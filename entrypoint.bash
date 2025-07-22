#!/usr/bin/env bash

set -e
set -x
set -u

cd "$ODOO_DIR/odoo"

# using exec to make it receive stop signals
exec ./venv/bin/python3 odoo-bin --config "$ODOO_DIR/.odoorc" "$@"
