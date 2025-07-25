#!/usr/bin/env bash

# TODO test if it works (not done yet either)

set -e
set -u

error() {
	error_message=$(
		cat "
$0 usage:
	-m | --module <module_name>
		Select the module to update / install
	-d | --drop
		Drop the database to restart an empty session"
	)
	[[ "$1" = "" ]] || echo "$1" 1>&2
	echo "$error_message" 1>&2
}

# default values
drop=0
install=0
help=0
module=""

while [[ "$#" -gt 0 ]]; do
	case $1 in
	-m | --module)
		module="$2"
		shift
		;;
	-d | --drop) drop=1 && install=1 ;;
	-i | --install) install=1 ;;
	-h | --help) help=1 ;;
	*)
		error "Unknown parameter passed: $1"
		exit 1
		;;
	esac
	shift
done

if [[ $help = 1 ]]; then
	error ""
	exit 0
fi

if [[ "$module" = "" ]]; then
	error "Unknown parameter passed: $1"
	exit 1
fi

echo "Module: $module"
echo "Should drop: $drop"
echo "Should -i $install"

echo docker compose up db
if [[ $drop = 1 ]]; then
	echo docker compose exec db psql 'DROP DATABASE $POSTGRES_DB;'
fi

action="-u"
if [[ $install = 1 ]]; then
	action="-i"
fi

echo docker compose down odoo
echo docker compose up odoo "$action $module"
