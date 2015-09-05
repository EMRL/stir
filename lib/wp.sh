#!/bin/bash
#
# pmfix()
#
# Checks for Wordpress upgrades, and executes upgrades if needed
#
# Many things planned here, eventually I will sed (in a log file?) 
# for the string "U = Update Available" before continuing the rest of this.
trace "Loading wp()"

function wp() {
    if [ -f $WORKPATH/$SITE/public/system/wp-settings.php ]; then
    cd $WORKPATH/$SITE/public; \
    trace "Current path is" $(pwd)
    #wp plugin status
        if yesno --default no "Update Wordpress? [y/N] "; then
            echo ""
            #wp plugin update --all
            #wp core update
            #wp core update-db   # this is mostly useless, as it updates only the development site's db :(
            cd /var/www/html/$SITE/; \
        else
            echo "Skipping Wordpress updates..."
        fi
    else
        trace "Wordpress not found."
    fi
}