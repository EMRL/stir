#!/bin/bash
#
# wp.sh
#
# Checks for Wordpress upgrades, and executes upgrades if needed
#
# Many things planned here, eventually I will sed (in a log file?) 
# for the string "U = Update Available" before continuing the rest of this.
trace "Loading wpress()"

function wPress() {
    trace "wp-cli found, proceeding with Wordpress updates."
    notice "Checking for required updates..."
    if hash wp 2>/dev/null; then

        if [ -f $WORKPATH/$APP/public/system/wp-settings.php ]; then
        cd $WORKPATH/$APP/public; \

            if yesno --default no "Update Wordpress? [y/N] "; then
                emptyLine
                trace "Updating plugins if needed."
                wp plugin update --all
                trace "Updating core if needed."
                wp core update
                wp core update-db   # this is mostly useless, as it updates only the development site's db :(
                cd $WORKPATH/$APP/; \
            else
                info "Skipping Wordpress updates..."
            fi
        else
            trace "Wordpress not found."
        fi
    else
        trace "wp-cli not found, skipping Wordpress updates."
    fi
}