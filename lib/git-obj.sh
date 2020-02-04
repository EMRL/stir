#!/usr/bin/env bash
#
# git-obj.sh
#
###############################################################################
# Functions related to handling files and branches
###############################################################################

# Initialize variables
var=(working_branch)
init_loop

###############################################################################
# checkout()
#   A simple function to handle git checkouts
#
# Arguments:
#   [branch]    The branch name to be checked out
################################################################################
function checkout() {
  if [[ -n "${1}" ]]; then
    working_branch="${1}"
    notice "Checking out ${working_branch} branch...";
    
    if [[ "${VERBOSE}" == "TRUE" ]]; then
      git checkout "${working_branch}" | tee --append "${logFile}"
    else
      if [[ "${QUIET}" != "1" ]]; then
        git checkout "${working_branch}" &>> "${logFile}" &
        showProgress
      else
        git checkout "${working_branch}" &>> "${logFile}"
      fi
    fi
  fi
}

# TODO: REWRITE
function push() {
  if [[ "${MERGE}" = "1" ]]; then
    trace "Push ${working_branch}";
    empty_line
    if [[ "${VERBOSE}" == "TRUE" ]]; then
      git push origin "${working_branch}" | tee --append "${logFile}"; error_check 
      trace "OK"              
    else
      if [[ "${FORCE}" = "1" ]] || yesno --default yes "Push ${working_branch} branch? [Y/n] "; then
        if [[ "${QUIET}" != "1" ]]; then
          sleep 1
          git push origin "${working_branch}" &>> "${logFile}" &
          spinner $!
          info "Success.    "
        else
          git push origin "${working_branch}" &>> "${logFile}"; error_check
        fi
        sleep 1
        if [[ "$(git status --porcelain)" ]]; then
          sleep 1; git add . &>> "${logFile}"
          git push --force-with-lease  &>> "${logFile}"
        fi
      else
        safeExit
      fi
    fi
  fi
}

###############################################################################
# merge()
#   Merges [branch] into the current working branch. If no variable is passed,
#   the value if MASTER is used
#
# Arguments:
#   [branch]    The branch to merge into current branch
################################################################################
function merge() {
  if [[ "${MERGE}" = "1" ]] && [[ "${working_branch}" != "${MASTER}" ]]; then
    notice "Merging ${MASTER} into ${working_branch}..."
    # Clear out the index.lock file, cause reasons
    # TODO: Find out why this is here, I can't remember what it was working around
    [[ -f "${gitLock}" ]] && rm "${gitLock}"
    if [[ "${VERBOSE}" == "TRUE" ]]; then
      git merge "${MASTER}" | tee --append "${logFile}"              
    else
      if [[ "${QUIET}" != "1" ]]; then
        # git merge --no-edit master &>> "${logFile}" &
        git merge "${MASTER}" &>> "${logFile}" &
        showProgress
      else
        git merge "${MASTER}" &>> "${logFile}"
      fi
    fi
  fi
}

###############################################################################
# confirm_branch()
#   Makes the the current branch is correct
#
# Arguments:
#   [branch]    The branch we confirmed being checked out, if left empty stir 
#               will assueme the current value of ${working_branch}
################################################################################
function confirm_branch() {
  if [[ -n "${1}" ]]; then
    working_branch="${1}"
  fi
  current_branch="$(git rev-parse --abbrev-ref HEAD)"
  if [[ "${current_branch}" != "${working_branch}" ]]; then 
    # If the user is awake at the console, allow them to try again
    if  [[ "${FORCE}" = "1" ]] || yesno --default yes "Current branch is ${current_branch} and should be ${working_branch}, try again? [Y/n] "; then
      if [[ "${current_branch}" = "${MASTER}" ]]; then 
        [[ -f "${gitLock}" ]] && rm "${gitLock}"
        git checkout "${working_branch}" &>> "${logFile}" #; error_check
      fi
    else
      safeExit
    fi
    # Were there any conflicts checking out?
    if grep -q "error: Your local changes to the following files would be overwritten by checkout:" "${logFile}"; then
      error "There is a conflict checking out."
    else
      trace "OK"
    fi 
  fi
}
