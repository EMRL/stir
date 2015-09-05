#!/bin/bash
#
# npm()
#
# Checks if project uses node.js, and runs package manager if needed.
# Also checks for Grunt, for backward compatibility with CAA.
trace "Loading npm()"

function npm() {
# Grunt check
    if [ $APP = "caa" ]; then
        echo ""

        if yesno --default no "Run Grunt? [y/N] "; then
            echo ""
            cd /var/www/html/$APP; \
            sudo grunt build --force
            sleep 1
        else
            echo "Skipping Grunt..."
        fi
    else
        sleep 1

        # node.js check
        NPM="/var/www/html/$APP/public/app/themes/$APP/package.json"
        if [ -f "$NPM" ]
            then
            echo ""
            if yesno --default no "Run Node Package Manager? [y/N] "; then
                cd /var/www/html/$APP/public/app/themes/$APP; \
                npm run build 2>/dev/null 1>>$tempfile &
                while ps |grep $! &>/dev/null; do
                echo -n "."
                sleep 1
                done
                echo -n "Complete."
                cd /var/www/html/$APP; \
                sleep 1
                echo ""
            else
                echo "Skipping Node Package Manager..."
            fi
        else
            sleep 1
        fi
    fi
}