#!/usr/bin/env bash

set -eu

PROJECT_DIR=$ODOO_DIR
cd "$PROJECT_DIR"

# clone and setup each project
for i in community enterprise tutorials; do
	echo "Setting up $i project..."
	# community edition should be cloned from "odoo" git repo
	CLONE_URL="git@github.com:odoo/$([[ $i == 'community' ]] && echo "odoo.git" || echo "$i.git")"
	[ ! -d "$PROJECT_DIR/$i" ] && git clone "$CLONE_URL" "$PROJECT_DIR/$i"

	# need to go into repo to setup git
	cd "$PROJECT_DIR/$i"

	# Check if the directory is already in the safe list
	if ! git config --global --get-all safe.directory | grep -q "$PROJECT_DIR/$i"; then
		# If not, add it
		git config --global --add safe.directory "$PROJECT_DIR/$i"
		echo "Added $PROJECT_DIR/$i to safe.directory"
	else
		echo "$PROJECT_DIR/$i is already in safe.directory"
	fi

	# community edition should be pushed to "odoo" git repo
	DEV_URL="git@github.com:odoo-dev/$([[ $i == 'community' ]] && echo "odoo.git" || echo "$i.git")"
	git remote add dev $DEV_URL || echo "Skipping remote creation"
	git remote set-url --push origin you_should_not_push_on_this_repository

	# go back to main (root) dir
	cd "$PROJECT_DIR"

	echo "Done setting up $i project..."
done

# No need for this since I now use odoo lsp
# # add odoo symlink for better code completion
# for i in enterprise tutorials; do
# 	rm -f "$PROJECT_DIR/$i/odoo" # to avoid symlink bug in ./community/odoo/odoo
# 	ln -s "$PROJECT_DIR/community/odoo" "$PROJECT_DIR/$i/odoo"
# done

# create global venv and install dependencies
cd "$PROJECT_DIR"
[ ! -d "$PROJECT_DIR/venv" ] && python3 -m venv "$PROJECT_DIR/venv"

# Extra python dependencies that were missing in requirements.txt
packages=(
	"debugpy"
	"inotify"
	"pdfminer"     # for attachment indexation of PDF documents
	"paramiko"     # for l10n_be_hr_payroll
	"phonenumbers" # for test_l10n_be_hr_payroll_account
	"websocket-client" # for tests using a browser
)
echo "Installing extra python dependencies in venv..."
./venv/bin/python3 -m pip install "${packages[@]}" 1>/dev/null

echo "Installing requirements.txt..."
./venv/bin/python3 -m pip install -r ./community/requirements.txt 1>/dev/null
