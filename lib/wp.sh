#!/bin/bash
#
# pmfix()
#
# Checks for Wordpress upgrades, and executes upgrades if needed
#
# Many things planned here, eventually I will sed (in a log file?) 
# for the string "U = Update Available" before continuing the rest of this.
echo "DEBUG: Loading wp()"

function wp() {
    cd /var/www/html/$SITE/public; \
    wp plugin status

    if yesno --default no "Update Wordpress? [y/N] "; then
        echo ""
        wp plugin update --all
        wp core update
        wp core update-db   # this is mostly useless, as it updates only the development site's db :(
        cd /var/www/html/$SITE/; \
    else
        echo "Skipping Wordpress updates..."
    fi
}