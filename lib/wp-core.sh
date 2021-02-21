#!/usr/bin/env bash
#
# wp-core.sh
#
###############################################################################
# Checks for Wordpress core updates
###############################################################################

# Initialize variables
var=(core_update core_update_complete)
init_loop

function wp_core() {
  # There's a little bug when certain plugins are spitting errors; work around 
  # seems to be to check for core updates a second time
  cd "${APP_PATH}"/"${WP_ROOT}"; \
  core_update="$(${wp_cmd} core check-update --format=csv | awk '{if(NR>1)print}')"

  if [[ -z "${core_update}" ]]; then
    info "Wordpress core is up to date."
    return
  fi
  
  # Write update info to log
  "${wp_cmd}" core check-update --no-color &>> "${log_file}"
  
  # Get update version number
  core_update="$(echo ${core_update} | cut -f1 -d',')"

  if [[ "${FORCE}" == "1" ]] || yesno --default no "A new version of Wordpress is available (${core_update}), update? [y/N] "; then
  
    # Check for composer
    if [[ -f "${APP_PATH}/composer.json" ]]; then
      trace "Found composer.json, updating"
      cd "${APP_PATH}"; \
      if [[ "${QUIET}" != "1" ]]; then
        # Execute the update
        info "Core update found, updating to ${core_update}"
        trace "Executing ${composer_cmd} update johnpbloch/wordpress-core"
        "${composer_cmd}" --no-progress update johnpbloch/wordpress-core &>> "${log_file}" &
        spinner $!
      else
        "${composer_cmd}" --no-progress update johnpbloch/wordpress-core &>> "${log_file}"
      fi
    fi

    # Assume updating via wp-cli
    cd "${WP_PATH}"; \
    if [[ "${QUIET}" != "1" ]]; then
      "${wp_cmd}" core update --no-color &>> "${log_file}" &
      spinner $!
    else
      "${wp_cmd}" core update --no-color &>> "${log_file}"
    fi

    # Double check upgrade was successful if we still see 'version' in the 
    # output, we must have missed the upgrade somehow
    "${wp_cmd}" core check-update --quiet --no-color &> "${trash_file}"
    if grep -aq "version" "${trash_file}"; then
      error "Core update failed.";
    else
      sleep 1
      cd "${APP_PATH}/"; # \ 
      info "Wordpress core updates complete."
      core_update_complete="1"
    fi
                                         
  else
    info "Skipping Wordpress core updates..."
  fi
}
