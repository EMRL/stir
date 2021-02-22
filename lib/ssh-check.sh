#!/usr/bin/env bash
#
# ssh-check.sh
#
############################################################################### 
# SSH checks for both Bitbucket and Github
###############################################################################

# TODO: Rewrite this to store git@domain stuff in a variable, allow for other
# REPO_HOSTs to work (Gitlab etc.) and shorten the entire function
function ssh_check() {
  if [[ "${NO_KEY}" != "TRUE" ]]; then
    trace "Checking SSH configuration"
    if [[ "${REPO_HOST}" == *"bitbucket"* ]]; then
      "${ssh_cmd}" -oStrictHostKeyChecking=no git@bitbucket.org &> /dev/null; error_status
      if [[ "${EXITCODE}" != "0" ]]; then
        error "git@bitbucket.org: SSH check failed (Error code ${EXITCODE})"
      else
        [[ "${TEST_SSH}" == "1" ]] && console "git@bitbucket.org: OK"
        trace "git@bitbucket.org: OK"
      fi
    elif [[ "${REPO_HOST}" == *"github"* ]]; then
      "${ssh_cmd}" -oStrictHostKeyChecking=no git@github.com &> /dev/null #; error_status     
      if [[ "${EXITCODE}" -gt "1" ]]; then
        error "git@github.com: SSH check failed (Error code ${EXITCODE})"
      else
        [[ "${TEST_SSH}" == "1" ]] && console "git@github.com: OK"
        trace "git@github.com: OK"
      fi
    fi
  fi
}
