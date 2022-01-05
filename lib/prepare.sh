#!/usr/bin/env bash
#
# prepare.sh
#
###############################################################################
# Runs user-defined prepare command
###############################################################################

function prepare() {

  # If running a command that is not going to touch code, we can skip the 
  # --prepare stuff altogether
  startup_switch=(REPORT DIGEST SCAN TEST_SSH TEST_EMAIL TEST_SLACK TEST_WEBHOOK \
    PUBLISH PROJSTATS CREATE_INVOICE FUNCTION_LIST VARIABLE_LIST)
  for arg in "${startup_switch[@]}"; do
    if [[ "${arg}" == "1" ]]; then
      PREPARE="FALSE"; return
    fi
  done

  # Should we reset before preparing project?
  if [[ "${PREPARE_WITH_RESET}" == "TRUE" ]] || [[ "${PREPARE_WITH_RESET}" == "1" ]]; then
    reset_local
  fi

  # Should we use our built-in Worpdress prepare clone function?
  if [[ "${PREPARE}" == "TRUE" ]] || [[ "${PREPARE}" == "1" ]]; then
    wp_check

    # Clone WP when necessary
    if [[ -n "${WP_PATH}" ]]; then
      wp_clone
    fi

    # If --prepare switch is being used, exit immediately
    if [[ "${PREPARE}" == "1" ]]; then
      quiet_exit
    else
      return
    fi
  fi
}
