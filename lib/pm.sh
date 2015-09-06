#!/bin/bash
#
# npm()
#
# Checks if project uses node.js, and runs package manager if needed.
# Also checks for Grunt, for backward compatibility with some of our older projects (Namely CAA)
trace "Loading pm()"

function pm() {
    # Grunt check
    if [ -d "$WORKPATH/$APP/lib" ]
        then
        emptyLine

        if yesno --default no "Run Grunt? [y/N] "; then
            emptyLine
            cd $WORKPATH/$APP; \
            sudo grunt build --force
        else
            info "Skipping Grunt..."
        fi
    else
        sleep 1

        # node.js check
        if [ -f "$WORKPATH/$APP/public/app/themes/$APP/package.json" ]
            then
            trace "$WORKPATH/$APP/public/app/themes/$APP/package.json found."
            emptyLine
            if yesno --default no "Run Node Package Manager? [y/N] "; then
                cd $WORKPATH/$APP/public/app/themes/$APP; \
                npm run build # 2>/dev/null 1>>$logFile &
            else
                info "Skipping Node Package Manager..."
            fi
        else
            trace "$WORKPATH/$APP/public/app/themes/$APP/package.json not found, skipping."
        fi
    fi
}