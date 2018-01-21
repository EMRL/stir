#!/usr/bin/env bash
#
# active-check.sh
#
###############################################################################
# Checks for recently active project files that may cause deployment issues
###############################################################################
trace "Loading activity checking"

# Initialize variables
read -r active_files <<< ""
echo "${active_files}" > /dev/null

function active_check() { 
  if [[ "${FORCE}" == "1" ]] && [[ "${UPGRADE}" == "1" ]] && [[ "${QUIET}" == "1" ]] && [[ "${ACTIVECHECK}" = "TRUE" ]]; then
    trace "Checking for active files"
    active_files=$(find "${WORKPATH}/${APP}" -mmin -"${CHECKTIME}" ! -path "${WORKPATH}/${APP}/public/app/wflogs/*" ! -path "${WORKPATH}/${APP}/.git/*" ! -path "${WORKPATH}/${APP}/.git")

    # Check for changed files and make sure they are actually waiting to be committed
    if [[ ! -z "${active_files}" ]] && [[ ! -z "$(git status --porcelain)" ]]; then
      trace "Recently changed files: ${active_files}"
      error "Code base has changed within the last ${CHECKTIME} minutes. Halting deployment."
    fi
  fi
}
