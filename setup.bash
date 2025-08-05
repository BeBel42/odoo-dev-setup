#!/usr/bin/env bash

# execute this first, even before creating docker image

# TODO remove pipfile if it still creates it

set -e
set -u

PROJECT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

# clone and setup each project
for i in odoo enterprise tutorials; do
	echo "Setting up $i project..."
	[ ! -d "$PROJECT_DIR/$i" ] && git clone --depth 1 "git@github.com:odoo/$i.git"
	cd "$PROJECT_DIR/$i"
	git config --global --add safe.directory "$PROJECT_DIR/$i"
	git remote add dev "git@github.com:odoo-dev/$i.git" || echo "Skipping remote creation"
	git remote set-url --push origin you_should_not_push_on_this_repository
	rm -f "$PROJECT_DIR/$i/pyrightconfig.json"
	ln -s "$PROJECT_DIR/pyrightconfig.json" "$PROJECT_DIR/$i/pyrightconfig.json"

	echo "Done setting up $i project..."
done

# add odoo symlink for better code completion
for i in enterprise tutorials; do
	rm -f "$PROJECT_DIR/$i/odoo" # to avoid symlink bug in ./odoo/odoo/odoo
	ln -s "$PROJECT_DIR/odoo/odoo" "$PROJECT_DIR/$i/odoo"
done

# create global venv and install dependencies
cd "$PROJECT_DIR"
[ ! -d "$PROJECT_DIR/venv" ] && python3 -m venv "$PROJECT_DIR/venv"
echo "Installing debugpy..."
./venv/bin/python3 -m pip install debugpy 1>/dev/null
echo "Installing odoo pip dependencies..."
./venv/bin/python3 -m pip install -r ./odoo/requirements.txt 1>/dev/null
