#!/usr/bin/env bash
#
# wp.sh
#
###############################################################################
# Checks for Wordpress upgrades, and executes upgrades if needed
###############################################################################

function wpPkg() {
  # Make sure we are allowed to update
  if [[ "${SKIPUPDATE}" != "1" ]]; then

    # Is wp-cli installed? 
    if hash "${WPCLI}"/wp 2>/dev/null; then
    trace status "wp-cli found, checking for Wordpress... "

      # Check for Wordpress
      if [[ -f "${WORKPATH}"/"${APP}${WPROOT}${WPSYSTEM}"/wp-settings.php ]]; then
        trace notime "FOUND"
        cd "${WORKPATH}"/"${APP}${WPROOT}${WPAPP}"; \

        # Database check
        trace status "Checking database... "
        "${WPCLI}"/wp db check &>> /dev/null; EXITCODE=$?; 
        if [[ "${EXITCODE}" != "0" ]]; then 
          "${WPCLI}"/wp db check &>> "${logFile}"; 
          trace notime "FAIL"
          if [[ "${AUTOMATE}" == "1" ]]; then
            error "There is a problem with your Wordpress installation, check your configuration."
          else
            info "There is a problem with your Wordpress installation, check your configuration."
          fi
        else
        	# Get info
        	trace notime "OK"
          wp core version --extra  &>> "${logFile}";

          # Check for Wordfence
          wfCheck
          
          # Look for updates
          if [[ "${QUIET}" != "1" ]]; then
            wpCheck &
            spinner $!
          else
            "${WPCLI}"/wp plugin status --no-color >> "${logFile}"
            "${WPCLI}"/wp plugin update --dry-run --no-color --all > "${wpFile}"
          fi

          # Check the logs
          #if grep -q "U = Update Available" "${logFile}"; then
          if grep -q "Available plugin updates:" "${wpFile}"; then    
            wpPlugins
          else
            # Was there a database glitch?
            if grep -q 'plugins can not be updated' "${wpFile}"; then
              sleep 1
            else
              info "Plugins are up to date."; UPD1="1"
            fi
          fi

          # Check log for core updates
          if [[ "${DONOTUPDATEWP}" == "TRUE" ]]; then
            trace "Wordpress core updates disabled, skipping"
          else
            wpCore
          fi
        fi
      else
        trace notime "NOT FOUND"
      fi
    else
      trace "wp-cli not found"
    fi

    # If running in Wordpress update-only mode, bail out
    if [[ "${UPGRADE}" == "1" ]] && [[ "${UPD1}" == "1" ]] && [[ "${UPD2}" == "1" ]]; then
      notice "No updates available, halting."
      safeExit
    fi
  fi
}

function wpCheck() {
  notice "Checking for updates..."

  # For the logfile
  "${WPCLI}"/wp plugin status --no-color &>> $logFile

  # For the console/smart commit message
  "${WPCLI}"/wp plugin update --dry-run --no-color --all &> "${wpFile}"

  # Other options, thanks Corey
  # wp plugin list --format=csv --all --fields=name,update_version,update | grep 'available'
  # wp plugin list --format=csv --all --fields=title,update_version,update | grep 'available'
}
