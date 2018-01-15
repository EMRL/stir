#!/bin/bash
#
# wp-plugins.sh
#
###############################################################################
# Checks for Wordpress plugin updates
###############################################################################

function wpPlugins() {
  # If available then let's do it
  info "The following updates are available:"
  # Clean the garbage out of the log for console display
  # This is all going to be rewritten
  sed 's/[+|]//g' "${wpFile}" > "${trshFile}" && mv "${trshFile}" "${wpFile}";
  sed '/^\s*$/d' "${wpFile}" > "${trshFile}" && mv "${trshFile}" "${wpFile}";
  # Remove lines with multiple sequential hyphens
  sed '/--/d' "${wpFile}" > "${trshFile}" && mv "${trshFile}" "${wpFile}";
  # Remove the column label row
  sed '1,/update_version/d' "${wpFile}" > "${trshFile}" && mv "${trshFile}" "${wpFile}";
  # Remove everything left but the first and fourth "words"
  awk '{print "  " $1,$4}' "${wpFile}" > "${trshFile}" && mv "${trshFile}" "${wpFile}";
  # Work around the weird "Available" bug
  sed '/Available/d' "${wpFile}" > "${trshFile}" && mv "${trshFile}" "${wpFile}";
  # Work around for the odd "REQUEST:" occuring
  sed '/REQUEST:/d' "${wpFile}" > "${trshFile}" && mv "${trshFile}" "${wpFile}";
  cat "${wpFile}" >> "${logFile}"

  # Display plugin list
  if [[ "${QUIET}" != "1" ]]; then
    cat "${wpFile}"; emptyLine
  fi

  if [[ "${FORCE}" = "1" ]] || yesno --default no "Proceed with updates? [y/N] "; then
    # If ACFPRO needs an update, do it first via wget
    if [[ "${QUIET}" != "1" ]]; then
      acf_update &
      spinner $!
    else
      acf_update
    fi

    # Let's get to work
    if [[ "${QUIET}" != "1" ]]; then
      "${WPCLI}"/wp plugin update --all --no-color &>> "${logFile}" &
      spinner $!
    else
      "${WPCLI}"/wp plugin update --all --no-color &>> "${logFile}" 
    fi  

    # Any problems with plugin updates?
    if grep -q 'Warning: The update cannot be installed because we will be unable to copy some files.' "${logFile}"; then
      error "One or more plugin updates have failed, probably due to problems with permissions."
    elif grep -q "Plugin update failed." "${logFile}"; then
      error "One or more plugin updates have failed."
    elif grep -q 'Warning: Update package not available.' "${logFile}"; then
      error "One or more update packages are not available. \nThis is often be caused by commercial plugins; check your log files."
    elif grep -q 'Error: Updated' "${logFile}"; then
      error "One or more plugin updates have failed."
    fi

    cd "${WORKPATH}"/"${APP}"/; \
    info "Plugin updates complete."
  else  
    info "Skipping plugin updates..."
  fi 
}
