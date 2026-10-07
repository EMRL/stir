###############################################################################
# check_dependencies()
#   Validate project requirements before Stir begins its main workflow.
#
#   This function checks that required commands, configuration files, and
#   project-specific dependencies are available for the requested operation.
#
#   Checks performed:
#     - Git is available on the system
#     - A project .stir.sh configuration exists, creating one when needed
#     - The project directory is writable when configuration must be created
#     - A configured deployment command exists
#     - Sendmail is available when email functionality is enabled
#     - A configured prepare file exists when using --prepare
#
#   When a project configuration file does not exist, the default
#   stir-project.sh file is copied into the project. If ${CONFIG_DIR} is set,
#   the configuration is placed there; otherwise it is created in the project
#   root as .stir.sh.
#
#   If nano is available, the user is offered an opportunity to edit a newly
#   created project configuration before continuing.
#
# Arguments:
#   None
#
# Uses:
#   ${APPRC}           Current project configuration path/status
#   ${WORK_PATH}       Root directory containing Stir projects
#   ${APP}             Current project name
#   ${CONFIG_DIR}      Optional directory for project configuration
#   ${stir_path}       Stir installation path
#   ${DEPLOY}          Configured deployment command
#   ${sendmail_cmd}    Resolved Sendmail command path
#   ${EMAIL_ERROR}     Enable email notifications for errors
#   ${EMAIL_SUCCESS}   Enable email notifications for successful operations
#   ${EMAIL_QUIT}      Enable email notifications when Stir exits
#   ${NOTIFYCLIENT}    Enable client email notifications
#   ${PREPARE}         Indicates a prepare operation is being performed
#   ${PREPARE_CONFIG}  Optional configuration file used during preparation
#
# Sets:
#   ${APPRC}           Path to a newly created project configuration file
#
# Returns:
#   Continues normally when all required dependencies are available.
#   Calls error() when a required dependency or configuration is unavailable.
#
# Example use:
#   check_dependencies
###############################################################################
check_dependencies() {
  local deploy_cmd=""

  # Is git installed?
  hash git 2>/dev/null || {
    error "stir ${VERSION} requires git to function properly."
  }

  # Does a configuration file for this repo exist?
  if [[ -z "${APPRC}" ]]; then
    # Make sure app directory is writable
    if [[ -w "${WORK_PATH}/${APP}" ]]; then
      empty_line
      info "Project configuration not found, creating."
      sleep 2

      # If configuration directory is defined
      if [[ -n "${CONFIG_DIR}" ]]; then
        if [[ ! -d "${WORK_PATH}/${APP}/${CONFIG_DIR}" ]]; then
          mkdir "${WORK_PATH}/${APP}/${CONFIG_DIR}"
        fi
        cp "${stir_path}/stir-project.sh" \
          "${WORK_PATH}/${APP}/${CONFIG_DIR}/.stir.sh"
        APPRC="${WORK_PATH}/${APP}/${CONFIG_DIR}/stir.sh"
      else
        # If using root directory for .stir.sh
        cp "${stir_path}/stir-project.sh" "${WORK_PATH}/${APP}/.stir.sh"
        APPRC="${WORK_PATH}/${APP}/.stir.sh"
      fi

      # Ask the user if they would like to edit
      if [[ -x "$(command -v nano)" ]]; then
        if yesno --default yes \
          "Would you like to edit the configuration file now? [Y/n] "; then
          nano "${APPRC}"
          clear
          sleep 1
          $(basename "${APP}") && exit
          # exec "/usr/local/bin/deploy ${STARTUP} ${APP}"
        fi
        info "You can change configuration later by editing ${APPRC}"
      fi
    else
      error "Project directory is not writable."
    fi
  fi

  # If a deploy command is declared, check that it actually exists.
  if [[ -n "${DEPLOY}" ]] && [[ "${DEPLOY}" != "SCP" ]]; then
    deploy_cmd="$(echo "${DEPLOY}" | head -n1 | awk '{print $1;}')"
    hash "${deploy_cmd}" 2>/dev/null || {
      error >&2 \
        "Unknown deployment command: ${DEPLOY} (${deploy_cmd} not found)"
    }
  fi

  # Do we need Sendmail, and if so can we find it?
  if [[ "${EMAIL_ERROR}" == "TRUE" ]] ||
     [[ "${EMAIL_SUCCESS}" == "TRUE" ]] ||
     [[ "${EMAIL_QUIT}" == "TRUE" ]] ||
     [[ "${NOTIFYCLIENT}" == "TRUE" ]]; then
    hash "${sendmail_cmd}" 2>/dev/null || {
      error "stir ${VERSION} requires Sendmail to function properly with your current configuration."
    }
  fi

  # If we're missing stuff that will be needed for --prepare, bail
  if [[ -n "${PREPARE}" ]]; then
    if [[ -n "${PREPARE_CONFIG}" ]] && [[ ! -f "${PREPARE_CONFIG}" ]]; then
      error "Can't read ${PREPARE_CONFIG}, exiting."
    fi
  fi
}
