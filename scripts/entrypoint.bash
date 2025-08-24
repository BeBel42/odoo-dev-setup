#!/usr/bin/env bash

# This is the entrypoint of the odoo docker container
# Arguments to this script will be directly passed to odoo-bin

set -eu

cd "$ODOO_DIR/"
odoo_command="$ODOO_DIR/community/odoo-bin --config=$ODOO_DIR/.odoorc $*"

echo -e "\033[0;35m$odoo_command\033[0m"

debug_params=""
if [[ $ENABLE_DEBUG = 1 ]]; then
	debug_params="-Xfrozen_modules=off -m debugpy --listen localhost:5678"
fi

set -x

# using exec to make it receive stop signals
exec "$ODOO_DIR/venv/bin/python3" $debug_params $odoo_command
