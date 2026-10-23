#!/usr/bin/env bash

# docker compose helpers for the odoo development containers
# meant to be sourced by other scripts, requires lib/log.bash
#
# expected globals:
#   compose_file     path to the docker-compose file
#   run_odoo also uses: cmd, docker_run_exec, docker_volumes, docker_build,
#   docker_service_ports, docker_entrypoint, enable_debug

# prefix prepended to all created / deleted database templates
database_template_prefix="odoo_template_"

# thin wrapper around docker compose
dc() {
    docker compose -f "$compose_file" "$@"
}

compose_down() {
    dc down --remove-orphans
}

start_db() {
    echo "Starting db container..."
    dc up -d db
}

# fails when the db is still unavailable after a few tries
wait_for_db() {
    tries=1
    while (! dc exec db pg_isready) && [ $tries -lt 5 ]; do
        sleep 1
        tries=$((tries + 1))
        echo "Checking database availability ($tries)..."
    done
    if [ $tries = 5 ]; then
        print_error "could not verify database availability"
        return 1
    fi
}

list_databases() {
    dc exec db sh -c "psql --user=\$POSTGRES_USER -l"
}

# drops every db template matching the regex given as $1
drop_db_templates() {
    dc exec db sh -c "psql --user=\$POSTGRES_USER -lqt | cut -d \| -f 1 | \
		grep -E '$database_template_prefix""$1' |
		xargs -n 1 dropdb --user=\$POSTGRES_USER --if-exists 2>/dev/null" &&
        echo "All matched templates have been deleted" ||
        print_warning "no template matched the given regex: $1"
}

# a failed drop only warns: the db may simply not exist
drop_current_db() {
    dc exec db sh -c "dropdb --user=\$POSTGRES_USER \$POSTGRES_DB" &&
        echo "Database dropped" ||
        print_warning "failed to drop database"
}

# replaces the current db with a copy of the template given as $1
copy_db_template() {
    (dc exec db sh -c "
        dropdb --if-exists --user=\"\$POSTGRES_USER\" \"\$POSTGRES_DB\" && \
        createdb --user=\"\$POSTGRES_USER\" -T \"$database_template_prefix""$1\" \"\$POSTGRES_DB\"
    " && echo "Successfully copied template $1") ||
        (print_error "could not use template $1" && exit 1)
}

# saves the current db as the template given as $1
save_db_template() {
    # the old template must be dropped first to override it
    dc exec db sh -c "dropdb --if-exists --user=\"\$POSTGRES_USER\" '$database_template_prefix""$1' 2>/dev/null" ||
        print_warning "failed to drop old \"$1\" template"
    dc exec db sh -c "createdb --user=\"\$POSTGRES_USER\" -T \"\$POSTGRES_DB\" '$database_template_prefix""$1'" &&
        echo "Template saved" ||
        print_warning "failed to create template database"
}

# runs the odoo container with the command built by the caller
run_odoo() {
    echo "Starting odoo container with \"$cmd\" parameters..."
    # the option variables are left unquoted on purpose: empty ones must disappear
    docker compose -f "$compose_file" $docker_run_exec $docker_volumes $docker_build -e "ENABLE_DEBUG=$enable_debug" $docker_service_ports $docker_entrypoint odoo $cmd
}

# full project setup through the setup container
setup_project() {
    echo '"--setup" specified. Calling setup container...'
    dc run --build --remove-orphans setup
    # files created from the container are owned by root, take them back
    echo "Setting owner of project to $USER..."
    sudo chown -R "$USER:$USER" .
    ln -s --force ./community/ruff.toml ./ruff.toml
    echo "Done setting up project."
}
