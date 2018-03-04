#!/usr/bin/env bash
#
# config-check.sh
#
###############################################################################
# Check to see if configuration files needs to be updated, and update if so
###############################################################################

# Initialize variables
read -r update_global update_user update_project env_settings project_config sed_hack <<< ""
echo "${update_global} ${update_user} ${update_project} ${project_config} ${sed_hack}" > /dev/null

function env_check() {
  # Only check when someone is at the console
  if [[ "${FORCE}" != "1" ]]; then
 
    # Compare version numbers
    if version_compare "${VERSION}" "${PROJECT_VERSION}"; then
      update_project="1"
    fi

    if version_compare "${VERSION}" "${USER_VERSION}"; then
      update_user="1"
    fi

    if version_compare "${VERSION}" "${GLOBAL_VERSION}"; then
      update_global="1"
    fi

    # User feedback
    info "\r\nNew version (${VERSION}) requires configuration updates."

    # Update?
    if yesno --default yes "Update now? [Y/n] "; then
      [[ "${update_project}" == "1" ]] && update_project
    else
      info "Skipping update."
    fi
  fi
}

function update_project() { 
  info "Updating ${project_config}..."
  env_settings=(PROJNAME PROJCLIENT DEVURL PRODURL)
  cp "${deployPath}"/deploy.sh "${trshFile}"

  # Loops through the variables
  for i in "${env_settings[@]}" ; do
    console "${i}"
    current_setting=$(grep "${i}" "${project_config}")

    # Don't bother parsing if we know it's not needed 

    # Add a check to make sure the value in the project config is not commented out, if it is 
    # we should leave that setting controlled by global/user file

    if [[ -n "${current_setting}" ]] && [[ -n "${i}" ]]; then
      console "current_setting = ${current_setting}"
      sed_hack=$(echo "sed -i -e '/${i}=.*/c ${current_setting}' ${trshFile}")
      console "${sed_hack}"
      eval "${sed_hack}"
    fi
  done

  # templorary for testing
  cp "${trshFile}" ~/result.txt
}
