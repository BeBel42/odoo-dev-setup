#!/usr/bin/env bash

set -eu

cd "$ODOO_DIR"

# TODO remove mlef by a read for name + odoo gram

# clone and setup each project
for i in community enterprise tutorials upgrade upgrade-util; do
	echo "Setting up $i project..."
	# community edition should be cloned from "odoo" git repo
	CLONE_URL="git@github.com:odoo/$([[ $i == 'community' ]] && echo "odoo.git" || echo "$i.git")"
	[ ! -d "$ODOO_DIR/$i/.git" ] && git clone "$CLONE_URL" "$ODOO_DIR/$i"

	# need to go into repo to setup git
	cd "$ODOO_DIR/$i"

	# To pass CLA runbot tests
	echo "Setting git user + email"
	git config user.name "Martin Lefèvre (mlef)"
	git config user.email mlef@odoo.com

	# Check if the directory is already in the safe list
	if ! git config --global --get-all safe.directory | grep -q "$ODOO_DIR/$i"; then
		# If not, add it
		git config --global --add safe.directory "$ODOO_DIR/$i"
		echo "Added $ODOO_DIR/$i to safe.directory"
	else
		echo "$ODOO_DIR/$i is already in safe.directory"
	fi

	if ! [[ $i = "upgrade" ]]; then # "upgrade" has no dev repo for some reason
		# community edition should be pushed to "odoo" git repo
		DEV_URL="git@github.com:odoo-dev/$([[ $i == 'community' ]] && echo "odoo.git" || echo "$i.git")"
		git remote add dev $DEV_URL || echo "Skipping remote creation"
		git remote set-url --push origin you_should_not_push_on_this_repository
	fi

	# go back to main (root) dir
	cd "$ODOO_DIR"

	echo "Done setting up $i project..."
done

# See https://github.com/odoo/odoo/wiki/Javascript-coding-guidelines#use-a-linter
cd "$ODOO_DIR/community/addons/web/tooling/"
bash enable.sh

# create global venv and install dependencies
cd "$ODOO_DIR"
{ [ ! -d "$ODOO_DIR/venv" ] || [ -z "$(ls -A "$ODOO_DIR/venv")" ]; } && python3 -m venv "$ODOO_DIR/venv"

# Extra python dependencies that were missing in requirements.txt
packages=(
	"debugpy"
	"ipdb"
	"inotify"
	"pdfminer"         # for attachment indexation of PDF documents
	"paramiko"         # for l10n_be_hr_payroll
	"phonenumbers"     # for test_l10n_be_hr_payroll_account
	"websocket-client" # for tests using a browser
	"pyjwt"            # for l10n_be_hr_payroll
)
echo "Installing extra python dependencies in venv..."
"$ODOO_DIR/venv/bin/python3" -m pip install "${packages[@]}" 1>/dev/null

echo "Installing requirements.txt..."
exec "$ODOO_DIR/venv/bin/python3" -m pip install -r "$ODOO_DIR/community/requirements.txt" 1>/dev/null
