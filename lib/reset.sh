#!/usr/bin/env bash
#
# reset.sh
#
###############################################################################
# Deletes local repo files, while keeping configuration intact
###############################################################################

function reset_local() {
  if [[ -n "${project_config}" ]] && [[ -w "${WORK_PATH}/${APP}" ]] && [[ "${DO_NOT_DEPLOY}" != "TRUE" ]]; then
    if [[ -n "${wp_cmd}" ]]; then
      eval "${wp_cmd}" db check  > /dev/null 2>&1
      EXITCODE=$?; 
      if [[ "${EXITCODE}" -eq "0" ]]; then
        info "Dropping Wordpress database..."
        eval "${wp_cmd}" db drop --yes
      fi
    fi

    if [[ -n "${CONFIG_BACKUP}" ]]; then
      if [[ ! -d "${CONFIG_BACKUP}" ]]; then
        if [[ -w "${CONFIG_BACKUP}" ]]; then
          trace status "Creating backup directory..."
          mkdir "${CONFIG_BACKUP}"; error_check
          trace notime "OK"
          else
          warning "Can not create ${CONFIG_BACKUP}"
        fi
      fi
      trace status "Backing up project settings to ${CONFIG_BACKUP}/${APP}-stir.sh... "
      cp "${project_config}" "${CONFIG_BACKUP}/${APP}-stir.sh"; error_check
      trace notime "OK"
    fi

    info "Resetting local files..."
    remove_local_files &
    spinner $!

    # Future home of better repo cloning
    # clone_project
    # verify_project
    # checkout "${MASTER}"

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
  mv "${project_config}" /tmp/"${APP}"-stir.sh &>> "${log_file}"
  rm -rf ${WORK_PATH}/${APP}/* &>> "${log_file}" 
  rm -rf ${WORK_PATH}/${APP}/.* &>> "${log_file}"
  mv /tmp/"${APP}"-stir.sh "${project_config}" &>> "${log_file}"
}
