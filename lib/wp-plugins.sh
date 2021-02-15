#!/usr/bin/env bash
#
# wp-plugins.sh
#
###############################################################################
# Checks for Wordpress plugin updates
###############################################################################

function wp_plugins() {
  # If available then let's do it
  info "The following updates are available:"
  # Clean the garbage out of the log for console display
  # This is all going to be rewritten
  sed 's/[+|]//g' "${wp_file}" > "${trash_file}" && mv "${trash_file}" "${wp_file}";
  sed '/^\s*$/d' "${wp_file}" > "${trash_file}" && mv "${trash_file}" "${wp_file}";
  # Remove lines with multiple sequential hyphens
  sed '/--/d' "${wp_file}" > "${trash_file}" && mv "${trash_file}" "${wp_file}";
  # Remove the column label row
  sed '1,/update_version/d' "${wp_file}" > "${trash_file}" && mv "${trash_file}" "${wp_file}";
  # Remove everything left but the first and fourth "words"
  awk '{print "  " $1,$4}' "${wp_file}" > "${trash_file}" && mv "${trash_file}" "${wp_file}";
  # Work around the weird "Available" bug
  sed '/Available/d' "${wp_file}" > "${trash_file}" && mv "${trash_file}" "${wp_file}";
  # Work around for the odd "REQUEST:" occuring
  sed '/REQUEST:/d' "${wp_file}" > "${trash_file}" && mv "${trash_file}" "${wp_file}";
  cat "${wp_file}" >> "${log_file}"

  # Display plugin list
  if [[ "${QUIET}" != "1" ]]; then
    cat "${wp_file}"; empty_line
  fi

  if [[ "${FORCE}" = "1" ]] || yesno --default no "Proceed with updates? [y/N] "; then
    # If ACFPRO needs an update, do it first via wget
    if [[ "${ACF_LOCK}" != "TRUE" ]]; then
      if grep -aq "advanced-custom-fields-pro" "${wp_file}"; then
        if [[ "${QUIET}" != "1" ]]; then
          acf_update &
        spinner $!
        else
          acf_update
        fi
      fi
    fi

    # First, check for for updates via composer
    if [[ -f "${APP_PATH}/composer.json" ]]; then
      trace "Found composer.json, updating"
      cd "${APP_PATH}"; \
      if [[ "${QUIET}" != "1" ]]; then
        "${composer_cmd}" --no-progress update &>> "${log_file}" &
        spinner $!
      else
        "${composer_cmd}" --no-progress update &>> "${log_file}"
      fi
      cd "${WP_PATH}"; \
    fi

    # Now, run the rest of the needed updates via wp-cli
    if [[ "${QUIET}" != "1" ]]; then
      "${wp_cmd}" plugin update --all --no-color &>> "${log_file}" &
      spinner $!
    else
      "${wp_cmd}" plugin update --all --no-color &>> "${log_file}" 
    fi  

    # Any problems with plugin updates?
    if grep -aq 'Warning: The update cannot be installed because we will be unable to copy some files.' "${log_file}"; then
      error "One or more plugin updates have failed, probably due to problems with permissions."
    elif grep -aq "Plugin update failed." "${log_file}"; then
      error "One or more plugin updates have failed."
    elif grep -aq 'Warning: Update package not available.' "${log_file}"; then
      error "One or more update packages are not available. \nThis is often be caused by commercial plugins; check your log files."
    elif grep -aq 'Error: Updated' "${log_file}"; then
      error "One or more plugin updates have failed."
    fi

    cd "${APP_PATH}"; \
    info "Plugin updates complete."
  else  
    info "Skipping plugin updates..."
    SMART_COMMIT="FALSE"
  fi 
}

###############################################################################
# add_plugin()
#   Adds plugins to a Wordpress project, using either composer or wp-cli 
#   depending on project setup 
#
# Arguments:
#   [plugin]    Name of the plugin. Will only work if plugin is tracked in 
#               the Wordpress plugin archive
############################################################################### 
function add_plugin() {
  # User will be doing something like `deploy --add-plugin wp-job-manager` from 
  # the shell
  # If composer:
  "${composer_cmd}" --no-progress require wpackagist-plugin/wp-job-manager:*
  # If no composer:
  wp plugin install wp-job-manager
}
