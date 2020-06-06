#!/usr/bin/env bash
#
# wp-core.sh
#
###############################################################################
# Checks for Wordpress core updates
###############################################################################

function wp_core() {
  # There's a little bug when certain plugins are spitting errors; work around 
  # seems to be to check for core updates a second time
  cd "${APP_PATH}"/"${WPROOT}"; \
  "${wp_cmd}" core check-update --no-color &>> "${logFile}"
  if grep -aq 'WordPress is at the latest version.' "${logFile}"; then
    info "Wordpress core is up to date."; UPD2="1"
  else
    sleep 1
    # Get files setup for smart commit
    "${wp_cmd}" core check-update --no-color &> "${coreFile}"
    
    # Strip out any randomly occuring debugging output
    grep -vE 'Notice:|Warning:|Strict Standards:|PHP' "${coreFile}" > "${trshFile}" && mv "${trshFile}" "${coreFile}";
    
    # Clean out the gobbleygook from wp-cli
    sed 's/[+|-]//g' "${coreFile}" > "${trshFile}" && mv "${trshFile}" "${coreFile}";
    cat "${coreFile}" | awk 'FNR == 1 {next} {print $1}' > "${trshFile}" && mv "${trshFile}" "${coreFile}";
    
    # Just in case, try to remove all blank lines. DOS formatting is 
    # messing up output with PHP crap
    sed '/^\s*$/d' "${coreFile}" > "${trshFile}" && mv "${trshFile}" "${coreFile}";
    
    # Remove line breaks, value should noe equal 'version x.x.x' or some such.
    sed ':a;N;$!ba;s/\n/ /g' "${coreFile}" > "${trshFile}" && mv "${trshFile}" "${coreFile}"
    # Remove everything up to and including the first space (in case of multiple core updates)
    sed -i 's/[^ ]* //' "${coreFile}"
    COREUPD=$(<$coreFile)

    if [[ -n "${COREUPD}" ]]; then
      # Update available!  \o/
      # echo -e "";
      trace "Core update ${COREUPD} available"
      # Update via composer if needed
      if [[ -f "${APP_PATH}/composer.json" ]]; then
        trace "Found composer.json, updating"
        cd "${APP_PATH}"; \
        if [[ "${QUIET}" != "1" ]]; then
          # Execute the update
          info "Core update found, updating to ${COREUPD}"
          trace "Executing ${composer_cmd} update johnpbloch/wordpress-core"
          "${composer_cmd}" update johnpbloch/wordpress-core &>> "${logFile}" &
          spinner $!
        else
          "${composer_cmd}" update johnpbloch/wordpress-core &>> "${logFile}"
        fi
        cd "${WP_PATH}"; \

      # Check for broken wp-cli garbage
      elif [[ "${COREUPD}" == *"PHP"* ]]; then
        warning "Checking for available core update was unreliable, skipping.";
      else
        if [[ "${FORCE}" = "1" ]] || yesno --default no "A new version of Wordpress is available (${COREUPD}), update? [y/N] "; then
          cd "${APP_PATH}/${WPROOT}"; \
          if [[ "${QUIET}" != "1" ]]; then
            "${wp_cmd}" core update --no-color &>> "${logFile}" &
            spinner $!
          else
            "${wp_cmd}" core update --no-color &>> "${logFile}"
          fi

          # Double check upgrade was successful if we still see 
          # 'version' in the output, we must have missed the upgrade 
          # somehow
          "${wp_cmd}" core check-update --quiet --no-color &> "${trshFile}"
          if grep -aq "version" "${trshFile}"; then
            error "Core update failed.";
          else
            sleep 1
            cd "${APP_PATH}/"; # \ 
            info "Wordpress core updates complete."; UPDCORE=1
          fi
                  
          # Update staging server database if needed
          if [[ "${UPDCORE}" = "1" ]] && [[ -n "${DEVURL}" ]]; then
            info "Upgrading staging database..."; "${curl_cmd}" --silent "${DEVURL}${WPSYSTEM}"/wp-admin/upgrade.php?step=1 >/dev/null 2>&1
          fi                          
        else
          info "Skipping Wordpress core updates..."
        fi
      fi
    fi
  fi  
}
