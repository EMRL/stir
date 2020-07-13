#!/usr/bin/env bash
#
# git.sh
#
###############################################################################
# Handles git related processes
###############################################################################

# Initialize variables
var=(FULLUSER SRC_BRANCH DEST_BRANCH)
init_loop

# Assign a variable to represent .git/index.lock
gitLock="${APP_PATH}/.git/index.lock"

# Commit, with message
function gitCommit() {
  # Smart commit stuff
  smart_commit; empty_line

  # Do a dry run; check for anything to commit
  git commit --dry-run &>> "${logFile}" 

  if grep -aq "nothing to commit, working directory clean" "${logFile}"; then 
    info "Nothing to commit, working directory clean."
    clean_exit
  else
    # Found stuff, let's get a commit message
    if [[ -z "${COMMITMSG}" ]]; then
      # while read -p "Enter commit message: " notes && [[ -z "$notes" ]]; do :; done
      read -rp "Enter commit message: " notes
      if [[ -z "${notes}" ]]; then
        console "Commit message must not be empty."
        read -rp "Enter commit message: " notes
        if [[ -z "${notes}" ]]; then
          console "Really?"
          read -rp "Enter commit message: " notes
        fi
        if [[ -z "${notes}" ]]; then
          console "Last chance."
          read -rp "Enter commit message: " notes
        fi
        if [[ -z "${notes}" ]]; then
          quiet_exit
        fi
      fi
    else
      # If running in -Fu (force updates only) mode, grab the Smart Commit 
      # message and skip asking for user input. Nice for cron updates. 
      if [[ "${FORCE}" = "1" ]] && [[ "${UPDATE}" = "1" ]]; then
        # We need Smart commits enabled or this can't work
        if [[ "${SMARTCOMMIT}" -ne "TRUE" ]]; then
          console "Smart Commits must be enabled when forcing updates."
          console "Set SMARTCOMMIT=TRUE in .stir.sh"; quiet_exit
        else
          if [[ -z "${COMMITMSG}" ]]; then
            info "Commit message must not be empty."; quiet_exit
          else
            notes="${COMMITMSG}"
          fi
        fi
      else
        # We want to be able to edit the default commit if available
        if [[ "${FORCE}" != "1" ]]; then
          notes="${COMMITMSG}"
          read -rp "Edit commit message: " -e -i "${COMMITMSG}" notes
          # Update the commit message based on user input ()
          notes="${notes:-$COMMITMSG}"
        else
          info "Using auto-generated commit message: ${COMMITMSG}"
          notes="${COMMITMSG}"
        fi
      fi
    fi

    if [[ "${REQUIREAPPROVAL}" == "TRUE" ]] && [[ "${APPROVE}" != "1" ]] && [[ "${DENY}" != "1" ]]; then 
      trace "Queuing commit message"
      echo "${notes}" > "${WORKPATH}/${APP}/.queued"
    else
      git commit -m "${notes}" &>> "${logFile}"; error_check
      trace "Commit message: ${notes}"
    fi
  fi

  # Check for bad characters in commit message
  echo "${notes}" > "${trshFile}"
  sed -i "s/\&/and/g" "${trshFile}"
  notes=$(<$trshFile)
}
