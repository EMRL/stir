#!/usr/bin/env bash
#
# ssh-check.sh
#
############################################################################### 
# SSH checks for both Bitbucket and Github
###############################################################################

# TODO: Rewrite this to store git@domain stuff in a variable, allow for other
# repohosts to work (Gitlab etc.) and shorten the entire function
function ssh_check() {
  if [[ "${NOKEY}" != "TRUE" ]]; then
    trace "Checking SSH configuration"
    if [[ "${REPOHOST}" == *"bitbucket"* ]]; then
      ssh -oStrictHostKeyChecking=no git@bitbucket.org &> /dev/null; error_status
      if [[ "${EXITCODE}" != "0" ]]; then
        error "git@bitbucket.org: SSH check failed (Error code ${EXITCODE})"
      else
        [[ "${SSHTEST}" == "1" ]] && console "git@bitbucket.org: OK"
        trace "git@bitbucket.org: OK"
      fi
    elif [[ "${REPOHOST}" == *"github"* ]]; then
      ssh -oStrictHostKeyChecking=no git@github.org &> /dev/null; error_status     
      if [[ "${EXITCODE}" != "0" ]]; then
        error "git@github.org: SSH check failed (Error code ${EXITCODE})"
      else
        [[ "${SSHTEST}" == "1" ]] && console "git@bitbucket.org: OK"
        trace "git@github.org: OK"
      fi
    fi
  fi
}
