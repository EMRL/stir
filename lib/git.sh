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

# Checkout master
function gitChkMstr() {
  if [[ -z "${MASTER}" ]]; then
    empty_line; error "stir ${VERSION} requires a master branch to be defined.";
  else
    current_branch="$(git rev-parse --abbrev-ref HEAD)"
    if [[ "${current_branch}" != "${MASTER}" ]]; then
      notice "Checking out master branch..."
      if [[ "${VERBOSE}" == "TRUE" ]]; then
        git checkout master | tee --append "${logFile}"            
      else
        if [[ "${QUIET}" != "1" ]]; then
          git checkout master &>> "${logFile}" &
          showProgress
        else
          git checkout master &>> "${logFile}"
        fi
      fi
    fi
  fi
}

# Garbage collection
#function gitGarbage() {
#  if [[ "${GARBAGE}" = "TRUE" ]] && [[ "${QUIET}" != "1" ]]; then 
#    notice "Preparing repository..."
#    git gc | tee --append "${logFile}"
#    if [[ "${QUIET}" != "1" ]]; then
#      git gc &>> "${logFile}"
#    fi
#  fi
#}

# Stage files
# function gitStage() {
  # Check for stuff that needs a commit
#  if [[ -z $(git status --porcelain) ]]; then
#    console "Nothing to commit, working directory clean."; quietExit
#  else
#    empty_line
#    if [[ "${FORCE}" = "1" ]] || yesno --default yes "Stage files? [Y/n] "; then
#      trace "Staging files"
#      if [[ "${VERBOSE}" == "TRUE" ]]; then
#        git add -A | tee --append "${logFile}"; error_check              
#      else  
#        git add -A &>> "${logFile}"; error_check
#      fi
#    else
#      trace "Exiting without staging files"; userExit    
#    fi
#  fi
#}

# Commit, with message
function gitCommit() {
  # Smart commit stuff
  smart_commit; empty_line

  # Do a dry run; check for anything to commit
  git commit --dry-run &>> "${logFile}" 

  if grep -aq "nothing to commit, working directory clean" "${logFile}"; then 
    info "Nothing to commit, working directory clean."
    safeExit
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
          quickExit
        fi
      fi
    else
      # If running in -Fu (force updates only) mode, grab the Smart Commit 
      # message and skip asking for user input. Nice for cron updates. 
      if [[ "${FORCE}" = "1" ]] && [[ "${UPDATE}" = "1" ]]; then
        # We need Smart commits enabled or this can't work
        if [[ "${SMARTCOMMIT}" -ne "TRUE" ]]; then
          console "Smart Commits must be enabled when forcing updates."
          console "Set SMARTCOMMIT=TRUE in .stir.sh"; quietExit
        else
          if [[ -z "${COMMITMSG}" ]]; then
            info "Commit message must not be empty."; quietExit
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

# Push master
function gitPushMstr() {
  if [[ -n "${MASTER}" ]]; then
    trace "Pushing ${MASTER}"
    empty_line  
    if [[ "${VERBOSE}" == "TRUE" ]]; then
      git push origin "${MASTER}" | tee --append "${logFile}"; error_check           
    else
      if  [[ "${FORCE}" = "1" ]] || yesno --default yes "Push ${MASTER} branch? [Y/n] "; then
        if [[ "${NOKEY}" != "TRUE" ]]; then
          if [[ "${QUIET}" != "1" ]]; then
            git push origin "${MASTER}" &>> "${logFile}" &
            spinner $!
            info "Success.    "
          else
            git push origin "${MASTER}" >> "${logFile}"; error_check
          fi
        else
          git push origin "${MASTER}" &>> "${logFile}"; error_check
        fi
      else
        safeExit
      fi
    fi
  fi
}

# Checkout production, now with added -f
#function gitChkProd() {
#  if [[ "${MERGE}" = "1" ]]; then
#    if [[ -n "${PRODUCTION}" ]]; then
#      notice "Checking out ${PRODUCTION} branch..."

#      if [[ "${VERBOSE}" == "TRUE" ]]; then
#        git checkout "${PRODUCTION}" | tee --append "${logFile}"; error_check               
#      else
#        if [[ "${QUIET}" != "1" ]]; then
#          git checkout "${PRODUCTION}" &>> "${logFile}" &
#          spinner $!
#          info "Success.    "
#        else
#          git checkout "${PRODUCTION}" &>> "${logFile}"; error_check
#        fi
#      fi

      # Make sure the branch currently checked out is production, if not
      # then let's try a ghetto fix
#      sleep 3; current_branch="$(git rev-parse --abbrev-ref HEAD)"
#      if [[ "${current_branch}" != "${PRODUCTION}" ]]; then
#        # If we're in that weird stuck mode on master, let's try to "fix" it
#        if  [[ "${FORCE}" = "1" ]] || yesno --default yes "Current branch is ${current_branch} and should be ${PRODUCTION}, try again? [Y/n] "; then
#          if [[ "${current_branch}" = "${MASTER}" ]]; then 
#            [[ -f "${gitLock}" ]] && rm "${gitLock}"
#            git add .; git checkout "${PRODUCTION}" &>> "${logFile}" #; error_check
#          fi
#        else
#          safeExit
#        fi
#      fi

      # Were there any conflicts checking out?
#      if grep -aq "error: Your local changes to the following files would be overwritten by checkout:" "${logFile}"; then
#         error "There is a conflict checking out."
#      else
#        trace "OK"
#      fi
#    fi
#  fi
}

# Merge master into production
# git merge --no-edit might be bugging, took it our for now
#function gitMerge() {
#  if [[ "${MERGE}" = "1" ]]; then
#    if [[ -n "${PRODUCTION}" ]]; then
#      notice "Merging ${MASTER} into ${PRODUCTION}..."
#      # Clear out the index.lock file, cause reasons
#      [[ -f "${gitLock}" ]] && rm "${gitLock}"
#      # Bonus add, just because. Ugh.
#      # git add -A; error_check 
#      if [[ "${VERBOSE}" == "TRUE" ]]; then
#        git merge "${MASTER}" | tee --append "${logFile}"              
#      else
#        if [[ "${QUIET}" != "1" ]]; then
#          # git merge --no-edit master &>> "${logFile}" &
#          git merge "${MASTER}" &>> "${logFile}" &
#          showProgress
#        else
#          git merge "${MASTER}"&>> "${logFile}"; error_check
#        fi
#      fi
#    fi
#  fi
#}

# Push production
#function gitPushProd() {
#  if [[ "${MERGE}" = "1" ]]; then
#    if [[ -n "${PRODUCTION}" ]]; then
#      trace "Push ${PRODUCTION}"
#      empty_line
#      if [[ "${VERBOSE}" == "TRUE" ]]; then
#        git push origin "${PRODUCTION}" | tee --append "${logFile}"; error_check 
#        trace "OK"              
#      else
#        if [[ "${FORCE}" = "1" ]] || yesno --default yes "Push ${PRODUCTION} branch? [Y/n] "; then
#          if [[ "${QUIET}" != "1" ]]; then
#            sleep 1
#            git push origin "${PRODUCTION}" &>> "${logFile}" &
#            spinner $!
#            info "Success.    "
#          else
#            git push origin "${PRODUCTION}" &>> "${logFile}"; error_check
#          fi
#          sleep 1
#          if [[ "$(git status --porcelain)" ]]; then
#            sleep 1; git add . &>> "${logFile}"
#            git push --force-with-lease  &>> "${logFile}"
#          fi
#        else
#          safeExit
#        fi
#      fi
#    fi

    # This is here temporarily to doubleplus force through a buggish situation
#    git checkout production &>> "${logFile}"
#    git merge master &>> "${logFile}"
#    git push origin "${PRODUCTION}" &>> "${logFile}"
#  fi
#}


