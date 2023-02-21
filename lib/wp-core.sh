#!/usr/bin/env bash
#
# wp-core.sh
#
###############################################################################
# Checks for Wordpress core updates
###############################################################################

# Initialize variables
var=(core_update_version core_update_complete core_current_version \
  composer_core_update core_update_attempt)
init_loop

function wp_core() {
  # There's a little bug when certain plugins are spitting errors; work around 
  # seems to be to check for core updates a second time
  cd "${APP_PATH}"/"${WP_ROOT}"; \
  core_update_version="$(eval ${wp_cmd[@]} core check-update --format=csv | awk '{if(NR>1)print}')"

  if [[ -z "${core_update_version}" ]]; then
    info "Wordpress core is up to date."
    return
  fi
  
  # Write update info to log
  eval "${wp_cmd}" core check-update --no-color &>> "${log_file}"
  
  # Get update version number
  core_update_version="$(echo ${core_update_version} | cut -f1 -d',')"
  # core_update_version="$(wp core check-update --field=version)"

  if [[ "${FORCE}" == "1" ]] || yesno --default no "A new version of Wordpress is available (${core_update_version}), update? [y/N] "; then
    
    # Check for composer
    if [[ -f "${APP_PATH}/composer.json" ]]; then
      trace "Found composer.json, updating"
      # Keep track of the fact that update has been attempted
      cd "${APP_PATH}"; \
      if [[ "${QUIET}" != "1" ]]; then
        # Execute the update
        info "Core update found, updating to ${core_update_version}"
        trace "Executing ${composer_cmd} update johnpbloch/wordpress-core"
        eval "${composer_cmd}" --no-progress update johnpbloch/wordpress --with-dependencies
 &>> "${log_file}" &
        spinner $!
      else
        eval "${composer_cmd}" --no-progress update johnpbloch/wordpress --with-dependencies
 &>> "${log_file}"
      fi
      composer_core_update="1"
      check_core_update_success; return
    else
      if [[ "${composer_core_update}" != "1" ]]; then
        # Assume updating via wp-cli
        trace "Executing core update"
        cd "${WP_PATH}"; \
        if [[ "${QUIET}" != "1" ]]; then
          eval "${wp_cmd}" core update --no-color &>> "${log_file}" &
          spinner $!
        else
          eval "${wp_cmd}" core update --no-color &>> "${log_file}"
        fi
        check_core_update_success; return
      fi
    fi                                       
  else
    info "Skipping Wordpress core updates..."
  fi
}

function check_core_update_success() {
  # Check update success
  core_update_attempt="1" 
  core_current_version="$(eval ${wp_cmd[@]} core version)"
  if [[ "${core_update_version}" != "${core_current_version}" ]]; then
    warning "Update to version ${core_update_version} failed, keeping version ${core_current_version}";
  else
    sleep 1
    cd "${APP_PATH}/"; # \ 
    info "Wordpress core updated to ${core_current_version}"
    core_update_complete="1"
  fi
}
