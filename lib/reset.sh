#!/usr/bin/env bash
#
# reset.sh
#
###############################################################################
# Deletes local repo files, while keeping configuration intact
###############################################################################

function reset_local() {
  if [[ -n "${project_config}" ]] && [[ -w "${WORKPATH}/${APP}" ]] && [[ "${DONOTDEPLOY}" != "TRUE" ]]; then

    if [[ -n "${wp_cmd}" ]]; then
      "${wp_cmd}" db check  > /dev/null 2>&1
      EXITCODE=$?; 
      if [[ "${EXITCODE}" -eq "0" ]]; then
        info "Dropping Wordpress database..."
        "${wp_cmd}" db drop --yes
      fi
    fi

    if [[ -n "${CONFIGBACKUP}" ]]; then
      trace status "Backing up project settings to ${CONFIGBACKUP}/${APP}-stir.sh... "
      cp "${project_config}" "${CONFIGBACKUP}/${APP}-stir.sh"; error_check
      trace notime "OK"
    fi

    info "Resetting local files..."
    remove_local_files &
    spinner $!

    if [[ -n "${PREPARE}" ]] && [[ "${PREPARE}" != "FALSE" ]]; then
      return
    else
      quiet_exit
    fi

  else
    warning "Can not reset this project."
    quiet_exit
  fi
}

function remove_local_files() {
  mv "${project_config}" /tmp/"${APP}"-stir.sh &>> "${logFile}"
  rm -rf ${WORKPATH}/${APP}/* &>> "${logFile}" 
  rm -rf ${WORKPATH}/${APP}/.* &>> "${logFile}"
  mv /tmp/"${APP}"-stir.sh "${project_config}" &>> "${logFile}"
}
