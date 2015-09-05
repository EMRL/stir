#!/bin/bash
#
# npm()
#
# Checks if project uses node.js, and runs package manager if needed.
# Also checks for Grunt, for backward compatibility with CAA.
echo "DEBUG: Loading npm()"

function npm() {
# Grunt check
    if [ $1 = "caa" ]; then
        echo ""

        if yesno --default no "Run Grunt? [y/N] "; then
            echo ""
            cd /var/www/html/$SITE; \
            sudo grunt build --force
            sleep 1
        else
            echo "Skipping Grunt..."
        #exit
        fi
    else
        sleep 1

        # node.js check
        NPM="/var/www/html/$SITE/public/app/themes/$SITE/package.json"
        if [ -f "$NPM" ]
            then
            echo ""
            if yesno --default no "Run Node Package Manager? [y/N] "; then
                cd /var/www/html/$SITE/public/app/themes/$SITE; \
                npm run build 2>/dev/null 1>>$tempfile &
                while ps |grep $! &>/dev/null; do
                echo -n "."
                sleep 1
                done
                echo -n "Complete."

                cd /var/www/html/$SITE; \
                sleep 1
                echo ""
            else
            echo "Skipping Node Package Manager..."
            #exit
            fi
        else
            sleep 1
        fi
    fi
}