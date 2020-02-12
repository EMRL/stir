#!/usr/bin/env bash
#
# wp.sh
#
###############################################################################
# Checks for Wordpress upgrades, and executes upgrades if needed
###############################################################################

# Initialize variables
var=(WP_PATH WP_SERVER_PID)
init_loop

function wp() {
  # Make sure we are allowed to update
  if [[ "${SKIPUPDATE}" != "1" ]] && [[ "${WP_PATH}" != "FALSE" ]]; then
    # Check for Wordfence
    wf_check
    
    cd "${WP_PATH}"

    notice "Checking for updates..."

    # Check log for core updates
    if [[ "${DONOTUPDATEWP}" == "TRUE" ]]; then
      trace "Wordpress core updates disabled, skipping"
    else
      wp_core
    fi
    
    # Look for updates
    if [[ "${QUIET}" != "1" ]]; then
      wp_update_check &
      spinner $!
    else
      "${wp_cmd}" plugin status --no-color >> "${logFile}"
      "${wp_cmd}" plugin update --dry-run --no-color --all > "${wpFile}"
    fi

    # Check the logs
    #if grep -aq "U = Update Available" "${logFile}"; then
    if grep -aq "Available plugin updates:" "${wpFile}"; then    
      wp_plugins
    else
      # Was there a database glitch?
      if grep -aq 'plugins can not be updated' "${wpFile}"; then
        sleep 1
      else
        info "Plugins are up to date."; UPD1="1"
      fi
    fi
  fi

  # If running in Wordpress update-only mode, bail out
  if [[ "${UPGRADE}" == "1" ]] && [[ "${UPD1}" == "1" ]] && [[ "${UPD2}" == "1" ]]; then
    notice "No updates available, halting."
    safeExit
  fi
}

function wp_update_check() {

  # For the logfile
  "${wp_cmd}" plugin status --no-color &>> $logFile

  # For the console/smart commit message
  "${wp_cmd}" plugin update --dry-run --no-color --all &> "${wpFile}"

  # Other options, thanks Corey
  # wp plugin list --format=csv --all --fields=name,update_version,update | grep -a 'available'
  # wp plugin list --format=csv --all --fields=title,update_version,update | grep -a 'available'
}

function wp_check() {
  # Is wp-cli installed? 
  if hash "${WPCLI}"/wp 2>/dev/null; then
    wp_cmd="${WPCLI}/wp"
    trace "wp-cli found at ${wp_cmd}"

    # Bug out if this is a new style project
    if [[ "${PREPARE}" == "TRUE" ]]; then 
      return
    fi

    if [[ -f "${WORKPATH}"/"${APP}${WPROOT}${WPSYSTEM}"/wp-settings.php ]]; then
      # Get Wordpress paths
      wp_path;

      # Local database check
      trace status "Checking database... "
      "${wp_cmd}" db check &>> /dev/null; EXITCODE=$?; 
      
      if [[ "${EXITCODE}" != "0" ]]; then 
        "${wp_cmd}" db check &>> "${logFile}"; 
        trace notime "FAIL"
        if [[ "${AUTOMATE}" == "1" ]]; then
          error "There is a problem with your Wordpress installation, check your configuration."
        else
          info "There is a problem with your Wordpress installation, check your configuration."
        fi
      else
        # Get info
        trace notime "OK"
        "${wp_cmd}" core version --extra  &>> "${logFile}";
      fi
    else
      WP_PATH="FALSE"
    fi
  fi
}

function wp_server_check {
  # Launch server
  # "${wp_cmd}" server --host=localhost > /dev/null 2>&1; EXITCODE=$?; 
  # if [[ "${EXITCODE}" -eq "0" ]]; then
    # trace "Launching server"
    # "${wp_cmd}" server --host=localhost >> "${logFile}" 2>&1 &
    # Keep checking for server to come online
    # until $(curl --output /dev/null --silent --head --fail http://localhost:8080); do
    #   sleep 1
    # done
  # fi

  trace "Activating plugins"
  "${wp_cmd}" plugin activate --all >> "${logFile}" 2>&1
  # trace "Activating theme"
  # "${wp_cmd}" theme activate site >> "${logFile}" 2>&1
  
  #"${curl_cmd}" -sL localhost:8080 | grep -E "Warning:|Fatal:" >> "${logFile}" 2>&1
  
  #if [[ -z "$(curl -sL localhost:8080 | grep -E "Warning:|Fatal:")" ]]; then
  #if curl -sL localhost:8080 | grep -E "Warning:|Fatal:" > /dev/null; then
  #  trace "Local server check passed";
  #else
  #  error "Local server check FAIL"
  #fi
}

function wp_path() {
  # Store path in variable and remove any extra /
  WP_PATH="${APP_PATH}${WPROOT}${WPAPP}"
  WP_PATH=$(sed -e "s^//^/^g" <<< ${WP_PATH})
  if [[ -d "${WP_PATH}" ]]; then
    cd "${WP_PATH}"; \
  fi
}

function wp_tmp {
  # Store path in variable and remove any extra /
  # WP_TMP="/tmp/${REPO}/${WPROOT}${WPAPP}"
  WP_TMP="/${WORKPATH}/${REPO}/${WPROOT}${WPAPP}"
  WP_TMP=$(sed -e "s^//^/^g" <<< $WP_TMP)
}
