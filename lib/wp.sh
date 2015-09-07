#!/bin/bash
#
# wp.sh
#
# Checks for Wordpress upgrades, and executes upgrades if needed
#
trace "Loading wpress()"

function wpPkg() {
  # Is wp-cli installed? 
  if hash wp 2>/dev/null; then
  trace "wp-cli found, checking for Wordpress."

    # Check for Wordpress
    if [ -f $WORKPATH/$APP/public/system/wp-settings.php ]; then
      trace "Wordpress found."
      cd $WORKPATH/$APP/public; \
      
      # Look for updates
      if [[ $VERBOSE -eq 1 ]]; then
        wp plugin status | tee --append $logFile               
        wp core check-update | tee --append $logfile
      else
        wpCheck &
        spinner $!
      fi

      # Check the logs
      if grep -q "U = Update Available" $logFile; then

        # If available then let's do it
        if  [ "$FORCE" = "1" ] || yesno --default no "Plugin updates available, proceed? [y/N] "; then
          wp plugin update --all &>> $logFile &
          spinner $!
          cd $WORKPATH/$APP/; \
          info "Plugin updates complete."
        else
          info "Skipping plugin updates..."
        fi
      else
        info "Plugins are up to date."
      fi

      # Check log for core updates
      # There's a little bug when certain plugins are spitting errors; work around seems to be 
      # to check for core updates a second time
      wp core check-update &>> $logFile
      if grep -q "Success: WordPress is at the latest version." $logFile; then
        info "Wordpress core is up to date."
      else
        sleep 1

        # Update available
        if  [ "$FORCE" = "1" ] || yesno --default no "A new version of Wordpress is available, update? [y/N] "; then
          wp core update &>> $logFile &
          spinner $!
          cd $WORKPATH/$APP/; \
          info "Wordpress core updates complete."
        else
          info "Skipping Wordpress core updates..."
        fi   
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