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

function wp_main() {
  # Make sure we are allowed to update
  if [[ "${SKIP_UPDATE}" != "1" ]] && [[ "${WP_PATH}" != "FALSE" ]]; then
    # Check for Wordfence
    wf_check
    
    cd "${WP_PATH}"

    # If if this is a manual ACF upgrade, jump right in
    if [[ "${UPDATE_ACF}" == "1" ]]; then
      error_detail="Adnvanced Custom Fields Pro is not installed in this project, nothing to update"
      "${wp_cmd}" plugin is-installed advanced-custom-fields-pro; error_check

      acf_update & spinner $!

      plugin_update_complete="1"
      plugins_updated="1"
      return
    fi

    notice "Checking for updates..."

    # Check log for core updates
    if [[ "${DO_NOT_UPDATE_WP}" == "TRUE" ]] || [[ "${UPDATE_ACF}" == "1" ]]; then
      trace "Skipping Wordpress core updates"
    else
      wp_core
    fi

    # Update plugins
    wp_plugins
  fi
 
  # If running in Wordpress update-only mode, bail out
  if [[ "${UPGRADE}" == "1" ]] && [[ "${UPD1}" == "1" ]] && [[ "${UPD2}" == "1" ]]; then
    notice "No updates available, halting."
    clean_exit
  fi
}

function wp_check() {
  # Is wp-cli installed? 
  if [[ -n "${wp_cmd}" ]]; then
    trace "wp-cli found at ${wp_cmd}"

    # Bug out if this is a new style project
    if [[ "${PREPARE}" == "TRUE" ]]; then 
      return
    fi

    if [[ -f "${WORK_PATH}"/"${APP}${WP_ROOT}${WP_SYSTEM}"/wp-settings.php ]]; then
      # Get Wordpress paths
      wp_path;

      # Local database check
      trace status "Checking database... "
      "${wp_cmd}" db check &>> /dev/null; EXITCODE=$?; 
      
      if [[ "${EXITCODE}" != "0" ]]; then 
        "${wp_cmd}" db check &>> "${log_file}"; 
        trace notime "FAIL"
        if [[ "${AUTOMATE}" == "1" ]]; then
          error "There is a problem with your Wordpress installation, check your configuration."
        else
          info "There is a problem with your Wordpress installation, check your configuration."
        fi
      else
        # Get info
        trace notime "OK"
        "${wp_cmd}" core version --extra  &>> "${log_file}";
      fi
    else
      WP_PATH="FALSE"
    fi
  fi
}

function wp_check_server {
  # Launch server
  # "${wp_cmd}" server --host=localhost > /dev/null 2>&1; EXITCODE=$?; 
  # if [[ "${EXITCODE}" -eq "0" ]]; then
    # trace "Launching server"
    # "${wp_cmd}" server --host=localhost >> "${log_file}" 2>&1 &
    # Keep checking for server to come online
    # until $(${curl_cmd} --output /dev/null --silent --head --fail http://localhost:8080); do
    #   sleep 1
    # done
  # fi

  trace "Activating plugins"
  "${wp_cmd}" plugin activate --all >> "${log_file}" 2>&1
  # trace "Activating theme"
  # "${wp_cmd}" theme activate site >> "${log_file}" 2>&1
  
  #"${curl_cmd}" -sL localhost:8080 | grep -E "Warning:|Fatal:" >> "${log_file}" 2>&1
  
  #if [[ -z "$(${curl_cmd} -sL localhost:8080 | grep -E "Warning:|Fatal:")" ]]; then
  #if "${curl_cmd}" -sL localhost:8080 | grep -E "Warning:|Fatal:" > /dev/null; then
  #  trace "Local server check passed";
  #else
  #  error "Local server check FAIL"
  #fi
}

function wp_path() {
  # Store path in variable and remove any extra /
  WP_PATH="${APP_PATH}${WP_ROOT}${WP_APP}"
  WP_PATH=$(sed -e "s^//^/^g" <<< ${WP_PATH})
  if [[ -d "${WP_PATH}" ]]; then
    cd "${WP_PATH}"; \
  fi
}

function wp_tmp {
  # Store path in variable and remove any extra /
  # WP_TMP="/tmp/${REPO}/${WP_ROOT}${WP_APP}"
  WP_TMP="/${WORK_PATH}/${REPO}/${WP_ROOT}${WP_APP}"
  WP_TMP=$(sed -e "s^//^/^g" <<< $WP_TMP)
}
