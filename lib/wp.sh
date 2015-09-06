#!/bin/bash
#
# wp.sh
#
# Checks for Wordpress upgrades, and executes upgrades if needed
#
# Many things planned here, eventually I will sed (in a log file?) 
# for the string "U = Update Available" before continuing the rest of this.
trace "Loading wpress()"

function wpPkg() {
    trace "wp-cli found, checking for Wordpress."
    if hash wp 2>/dev/null; then

        if [ -f $WORKPATH/$APP/public/system/wp-settings.php ]; then
            trace "Wordpress found."
            cd $WORKPATH/$APP/public; \
            
            if [[ $VERBOSE -eq 1 ]]; then
                wp plugin status | tee --append $logFile               
                wp core check-update | tee --append $logfile
            else
                wpCheck &
                spinner $!
            fi

            if grep -q "U = Update Available" $logFile; then

                if yesno --default no "Update Wordpress? [y/N] "; then
                    wpUpdate &
                    spinner $!
                    cd $WORKPATH/$APP/; \
                    info "Updates complete."
                else
                    info "Skipping Wordpress updates..."
                fi

            else
                info "Wordpress is up to date."
            fi

        else
            trace "Wordpress not found."
        fi

    else
        trace "wp-cli not found, skipping Wordpress updates."
    fi
}

function wpCheck() {
    notice "Checking for updates..."
    wp plugin status &>> $logFile
    wp core check-update &>> $logFile
}

function wpUpdate() {
    trace "Updating plugins if needed." 
    wp plugin update --all &>> $logFile
    trace "Updating core if needed."
    wp core update &>> $logFile   
}