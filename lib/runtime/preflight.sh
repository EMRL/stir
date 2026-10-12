#!/usr/bin/env bash
#
# preflight.sh

# Initialize variables
var=(integer_check json_key json_num cleaned_date cleaned_path wp_cmd \
  composer_cmd cmd_string)
init_loop

###############################################################################
# preflight()
#   Perform preliminary checks and prepare the runtime environment before
#   beginning Stir's main workflow.
#
#   Handles server monitoring, backup and scan checks, user confirmation,
#   special operations, deployment locks, permissions, and runtime overrides.
#
# Arguments:
#   None
#
# Returns:
#   Continues when all preflight checks pass.
#   Calls quiet_exit() when execution should stop.
#
# Example use:
#   preflight
###############################################################################
go() {
  if [[ "${QUIET}" != "1" ]]; then
    tput cnorm;
  fi

  # Get some project data for the logs; we only want to get server monitor 
  # info if we're not running a monitor test since we already loaded the 
  # password file contents into a variable
  if [[ "${TEST_MONITOR}" != "1" ]]; then
    server_monitor
  fi
  scan_check
  test_backup

  console "stir ${VERSION}"

  # Are we skipping git functions?
  if [[ "${SKIP_GIT}" == "1" ]]; then 
    if [[ "${DIGEST}" != "1" || "${SWITCHES}" == *"test"*  ]]; then
      error "Skipping git functionality is only allowed when using --digest or test switches"
    fi
  fi

  # Build only
  if [[ "${BUILD}" == "1" ]]; then
    build_check; quiet_exit
  fi  

  if [[ "${INCOGNITO}" != "TRUE" ]]; then
    console "Current working path is ${APP_PATH}"
  fi

  # Generate stats
  if [[ "${PROJ_STATS}" == "1" ]]; then
    build_stats; quiet_exit
  fi

  # Chill and wait for user to confirm project
  if  [[ "${FORCE}" == "1" || "${SCAN}" == "1" || "${PROJ_STATS}" == "1" ]] || yesno --default yes "Continue? [Y/n] "; then
    trace "Loading project"
  else
    quiet_exit
  fi

  # Is this project locked?
  if [[ "${DO_NOT_DEPLOY}" == "TRUE" ]]; then
    warning "This project is currently locked."; quiet_exit
  fi

  # Is the user root?
  if [[ "${ALLOW_ROOT}" != "TRUE" ]] && [[ "${EUID}" -eq "0" ]]; then
    warning "Can't continue as root."; quiet_exit
  fi

  # Disallow server check?
  if [[ "${NO_CHECK}" == "1" ]]; then
    CHECK_SERVER="FALSE";
    CHECK_ACTIVE="FALSE"
  fi

  # if git.lock exists, do we want to remove it?
  if [[ -f "${git_lock}" ]]; then
    warning "Found ${git_lock}"
    # If running in --force mode we will not allow deployment to continue
    if [[ "${FORCE}" = "1" ]]; then
      warning "Can't continue using --force."; quiet_exit
    else
      if yesno --default no "Remove lockfile? [y/N] "; then
        rm -f "${git_lock}" 2>/dev/null
        sleep 1
      else
        quiet_exit
      fi
    fi
  fi

  if [[ "${NEWS_URL}" == "FALSE" ]]; then
    var=(NEWS_URL)
    init_loop
  fi
}
