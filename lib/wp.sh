#!/bin/bash
#
# pmfix()
#
# Checks for Wordpress upgrades, and executes upgrades if needed
#
# Many things planned here, eventually I will sed (in a log file?) 
# for the string "U = Update Available" before continuing the rest of this.
trace "Loading wpress()"

function wpress() {
    if hash wp 2>/dev/null; then
    trace "wp-cli found, proceeding with Wordpress updates."

        if [ -f $WORKPATH/$APP/public/system/wp-settings.php ]; then
        cd $WORKPATH/$APP/public; \
        trace "Current path is" $(pwd)
        wp plugin status
            if yesno --default no "Update Wordpress? [y/N] "; then
                echo ""
                wp plugin update --all
                wp core update
                wp core update-db   # this is mostly useless, as it updates only the development site's db :(
                cd /var/www/html/$APP/; \
            else
                echo "Skipping Wordpress updates..."
            fi
        else
            trace "Wordpress not found."
        fi
    else
        trace "wp-cli not found, skipping Wordpress updates."
    fi
}