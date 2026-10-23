#!/usr/bin/env bash

# desktop notification helpers, meant to be sourced by other scripts
# requires lib/log.bash
#
# expected globals:
#   disable_notifications  set to 1 to turn the notification off
#   project_dir            used to locate the odoo icon

# meant to be called from an EXIT trap
notify_script_finished() {
    if [[ $disable_notifications = 1 ]]; then
        return
    fi
    odoo_icon_path="$project_dir/images/odoo_logo_small.png"
    if type notify-send 1>/dev/null 2>&1; then
        notify-send "Odoo" "Script execution finished" -t 2000 -u critical -i "$odoo_icon_path"
    else
        print_warning "notify-send is not installed on your system. Notifications won't be sent."
    fi
}
