#!/usr/bin/env bash

set -e
set -u

# TODO add xml dev parameters (in config?)

error() {
	error_message="
$0 usage:
	-m | --module <module_name>
		Select the module to update / install.
	-d | --drop
		Drop the database to start on an empty session.
		This will automatically reinstall the module.
	-i | --install
		Installs the module in the database.
	-h | --help
		Show this help prompt."
	[[ "$1" = "" ]] || echo "$1" 1>&2
	echo "$error_message" 1>&2
}

# default values
drop=0
install=0
help=0
module=""

# parse script parameters
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
		error "Error: unknown parameter passed: \"$1\""
		exit 1
		;;
	esac
	shift
done

# show help prompt
if [[ $help = 1 ]]; then
	error ""
	exit 0
fi

# user did not mention module name (-m | --module <module_name>)
if [[ "$module" = "" ]]; then
	set +u
	error "Error: missing module (-m) parameter"
	exit 1
fi

echo "Starting db container..." 1>&2
echo docker compose up db
echo "Shutting down odoo container..." 1>&2
echo docker compose down odoo

if [[ $drop = 1 ]]; then
	echo '"--drop" has been specified. Dropping postgres database...' 1>&2
	echo docker compose exec db psql 'DROP DATABASE $POSTGRES_DB;'
fi

if [[ $install = 1 ]]; then
	echo "\"$( ([[ $drop = 1 ]] && echo '--drop') || echo '--install')\"" \
		'has been specified. Adding "-i" to command' 1>&2
	action="-i"
else
	echo '"--install" has not been specified. Adding "-u" to command' 1>&2
	action="-u"
fi

cmd="$action $module"
echo "Starting odoo container with \"$cmd\" parameters..." 1>&2
echo docker compose up odoo "$cmd"
