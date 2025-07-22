#!/usr/bin/env bash

# execute this first, even before creating docker image

set -e
set -u

PROJECT_DIR=$(pwd)

[ ! -d "$PROJECT_DIR"/enterprise ] && git clone --depth 1 git@github.com:odoo/enterprise.git
[ ! -d "$PROJECT_DIR"/odoo ] && git clone --depth 1 git@github.com:odoo/odoo.git
[ ! -d "$PROJECT_DIR"/tutorials ] && git clone --depth 1 git@github.com:odoo/tutorials.git

git config --global --add safe.directory "$PROJECT_DIR/odoo"
git config --global --add safe.directory "$PROJECT_DIR/enterprise"
git config --global --add safe.directory "$PROJECT_DIR/tutorials"

cd "$PROJECT_DIR/odoo"
git remote add dev git@github.com:odoo-dev/odoo.git || echo "Skipping remote creation"
git remote set-url --push origin you_should_not_push_on_this_repository

cd "$PROJECT_DIR/enterprise"
git remote add dev git@github.com:odoo-dev/enterprise.git || echo "Skipping remote creation"
git remote set-url --push origin you_should_not_push_on_this_repository

cd "$PROJECT_DIR/tutorials"
git remote add dev git@github.com:odoo-dev/tutorials.git || echo "Skipping remote creation"
git remote set-url --push origin you_should_not_push_on_this_repository

cd "$PROJECT_DIR/odoo"
python3 -m venv venv
./venv/bin/python3 -m pip install -r requirements.txt
