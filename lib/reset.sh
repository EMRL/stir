#!/usr/bin/env bash
#
# reset.sh
#
###############################################################################
# Deletes local repo files, while keeping configuration intact
###############################################################################

function reset_local() {
  if [[ -n "${project_config}" ]] && [[ -w "${WORKPATH}/${APP}" ]]; then

    if [[ -n "${wp_cmd}" ]]; then
      # TODO: Add a better check here someday
      info "Dropping Wordpress database..."
      "${wp_cmd}" db drop --yes
    fi

    info "Resetting local files..."
    remove_local_files &
    spinner $!

    if [[ -n "${PREPARE}" ]] && [[ "${PREPARE}" != "FALSE" ]]; then
      return
    else
      quietExit
    fi

  else
    warning "Can not reset this project"
  fi
}

function remove_local_files() {
  mv "${project_config}" /tmp/"${APP}"-stir.sh &>> "${logFile}"
  rm -rf ${WORKPATH}/${APP}/* &>> "${logFile}" 
  rm -rf ${WORKPATH}/${APP}/.* &>> "${logFile}"
  mv /tmp/"${APP}"-stir.sh "${project_config}" &>> "${logFile}"
}