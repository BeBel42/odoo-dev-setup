#!/usr/bin/env bash

# This is the entrypoint of the odoo docker container
# Arguments to this script will be directly passed to odoo-bin

set -e
set -x
set -u

cd "$ODOO_DIR/"
# using exec to make it receive stop signals
exec "$ODOO_DIR/venv/bin/python3" \
	-Xfrozen_modules=off \
	-m debugpy \
	--listen 0.0.0.0:5678 \
	"$ODOO_DIR/community/odoo-bin" \
	--config "$ODOO_DIR/.odoorc" "$@"
