#!/usr/bin/env bash
#
# active-check.sh
#
###############################################################################
# Checks for recently active project files that may cause deployment issues
###############################################################################

# Initialize variables
var=(active_files)
init_loop

function check_active() { 
  if [[ "${FORCE}" == "1" ]] && [[ "${UPGRADE}" == "1" ]] && [[ "${QUIET}" == "1" ]] && [[ "${CHECK_ACTIVE}" = "TRUE" ]]; then
    trace "Checking for active files"
    active_files=$(find "${WORK_PATH}/${APP}" -mmin -"${CHECK_TIME}" ! -path "${WORK_PATH}/${APP}/public/app/wflogs" ! -path "${WORK_PATH}/${APP}/.git/*" ! -path "${WORK_PATH}/${APP}/.git")

    # Check for changed files and make sure they are actually waiting to be committed
    if [[ ! -z "${active_files}" ]] && [[ ! -z "$(git status --porcelain)" ]]; then
      trace "Recently changed files: ${active_files}"
      error "Code base has changed within the last ${CHECK_TIME} minutes. Halting deployment."
    fi
  fi
}
