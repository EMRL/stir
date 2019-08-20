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

# Make sure we're in a git repository.
function gitStart() {
  # If this is just a build, we won't require git repo functions
  if [[ "${BUILD}" == "1" ]]; then 
    return 0
  fi
  
  # Directory exists?
  if [[ ! -d "${APP_PATH}" ]]; then
    info "${APP_PATH} is not a valid directory."
    clean_up; exit 34
  else
    cd "${APP_PATH}" || error_check
  fi

  # Check that .git exists
  if [[ -f "${APP_PATH}/.git/index" ]]; then
    sleep 1
  else
    info "There is no working project at ${APP_PATH}"
    clean_up; exit 51
  fi

  # Make sure there has been at least one commit previously made
  git rev-parse --abbrev-ref HEAD &>> "${trshFile}"
  if grep -q "fatal" "${trshFile}"; then 
    error "Unable to start, push your first commit manually and try again."
  else  
    # If running --automate, force a branch check
    if [[ "${AUTOMATE}" == "1" ]]; then
      CHECKBRANCH="${MASTER}"
    fi
    # If CHECKBRANCH is set, make sure current branch is correct.
    start_branch="$(git rev-parse --abbrev-ref HEAD)"
    if [[ -n "${CHECKBRANCH}" ]] && [[ "${DIGEST}" != "1" ]] && [[ "${PROJSTATS}" != "1" ]] && [[ "${EMAILTEST}" != "1" ]] && [[ "${SLACKTEST}" != "1" ]]; then 
      if [[ "${start_branch}" != "${CHECKBRANCH}" ]]; then
        error "Must be on ${CHECKBRANCH} branch to continue.";
      fi
    fi
  fi

  # Check for active files
  check_active

  # If running --automate, pull and sync all branches
  if [[ "${AUTOMATE}" == "1" ]]; then
    trace "Syncing with origin"
    git pull --all &>> "${logFile}"; error_check
  fi

  # Try to clear out old git processes owned by this user, if they exist
  pkill -f git &>> /dev/null || true
}

# Checkout master
function gitChkMstr() {
  if [[ -z "${MASTER}" ]]; then
    empty_line; error "stir ${VERSION} requires a master branch to be defined.";
  else
    current_branch="$(git rev-parse --abbrev-ref HEAD)"
    if [[ "${current_branch}" != "${MASTER}" ]]; then
      notice "Checking out master branch..."; fix_index
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
function gitGarbage() {
  if [[ "${GARBAGE}" = "TRUE" ]] && [[ "${QUIET}" != "1" ]]; then 
    notice "Preparing repository..."
    git gc | tee --append "${logFile}"
    if [[ "${QUIET}" != "1" ]]; then
      git gc &>> "${logFile}"
    fi
  fi
}

# Does anything need to be committed? (Besides me?)
function gitStatus() {
  if [[ -z "$(git status --porcelain)" ]]; then
    if [[ "${APPROVE}" != "1" ]] && [[ "${DENY}" != "1" ]]; then
      if [[ "${REQUIREAPPROVAL}" == "TRUE" ]]; then
        console "Nothing to queue, working directory clean."
      else
        console "Nothing to commit, working directory clean."
      fi
      quietExit
    fi
  fi
}

# Stage files
function gitStage() {
  # Check for stuff that needs a commit
  if [[ -z $(git status --porcelain) ]]; then
    console "Nothing to commit, working directory clean."; quietExit
  else
    empty_line
    if [[ "${FORCE}" = "1" ]] || yesno --default yes "Stage files? [Y/n] "; then
      trace "Staging files"
      if [[ "${VERBOSE}" == "TRUE" ]]; then
        git add -A | tee --append "${logFile}"; error_check              
      else  
        git add -A &>> "${logFile}"; error_check
      fi
    else
      trace "Exiting without staging files"; userExit    
    fi
  fi
}

# Commit, with message
function gitCommit() {
  # Smart commit stuff
  smart_commit; empty_line

  # Do a dry run; check for anything to commit
  git commit --dry-run &>> "${logFile}" 

  if grep -q "nothing to commit, working directory clean" "${logFile}"; then 
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
    trace "Pushing ${MASTER}"; fix_index
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
function gitChkProd() {
  if [[ "${MERGE}" = "1" ]]; then
    if [[ -n "${PRODUCTION}" ]]; then
      notice "Checking out ${PRODUCTION} branch..."; fix_index

      if [[ "${VERBOSE}" == "TRUE" ]]; then
        git checkout "${PRODUCTION}" | tee --append "${logFile}"; error_check               
      else
        if [[ "${QUIET}" != "1" ]]; then
          git checkout "${PRODUCTION}" &>> "${logFile}" &
          spinner $!
          info "Success.    "
        else
          git checkout "${PRODUCTION}" &>> "${logFile}"; error_check
        fi
      fi

      # Make sure the branch currently checked out is production, if not
      # then let's try a ghetto fix
      sleep 3; current_branch="$(git rev-parse --abbrev-ref HEAD)"
      if [[ "${current_branch}" != "${PRODUCTION}" ]]; then
        # If we're in that weird stuck mode on master, let's try to "fix" it
        if  [[ "${FORCE}" = "1" ]] || yesno --default yes "Current branch is ${current_branch} and should be ${PRODUCTION}, try again? [Y/n] "; then
          if [[ "${current_branch}" = "${MASTER}" ]]; then 
            [[ -f "${gitLock}" ]] && rm "${gitLock}"
            git add .; git checkout "${PRODUCTION}" &>> "${logFile}" #; error_check
          fi
        else
          safeExit
        fi
      fi

      # Were there any conflicts checking out?
      if grep -q "error: Your local changes to the following files would be overwritten by checkout:" "${logFile}"; then
         error "There is a conflict checking out."
      else
        trace "OK"
      fi
    fi
  fi
}

# Merge master into production
# git merge --no-edit might be bugging, took it our for now
function gitMerge() {
  if [[ "${MERGE}" = "1" ]]; then
    if [[ -n "${PRODUCTION}" ]]; then
      notice "Merging ${MASTER} into ${PRODUCTION}..."; fix_index
      # Clear out the index.lock file, cause reasons
      [[ -f "${gitLock}" ]] && rm "${gitLock}"
      # Bonus add, just because. Ugh.
      # git add -A; error_check 
      if [[ "${VERBOSE}" == "TRUE" ]]; then
        git merge "${MASTER}" | tee --append "${logFile}"              
      else
        if [[ "${QUIET}" != "1" ]]; then
          # git merge --no-edit master &>> "${logFile}" &
          git merge "${MASTER}" &>> "${logFile}" &
          showProgress
        else
          git merge "${MASTER}"&>> "${logFile}"; error_check
        fi
      fi
    fi
  fi
}

# Push production
function gitPushProd() {
  if [[ "${MERGE}" = "1" ]]; then
    if [[ -n "${PRODUCTION}" ]]; then
      trace "Push ${PRODUCTION}"; fix_index
      empty_line
      if [[ "${VERBOSE}" == "TRUE" ]]; then
        git push origin "${PRODUCTION}" | tee --append "${logFile}"; error_check 
        trace "OK"              
      else
        if [[ "${FORCE}" = "1" ]] || yesno --default yes "Push ${PRODUCTION} branch? [Y/n] "; then
          if [[ "${QUIET}" != "1" ]]; then
            sleep 1
            git push origin "${PRODUCTION}" &>> "${logFile}" &
            spinner $!
            info "Success.    "
          else
            git push origin "${PRODUCTION}" &>> "${logFile}"; error_check
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

    # This is here temporarily to doubleplus force through a buggish situation
    git checkout production &>> "${logFile}"
    git merge master &>> "${logFile}"
    git push origin "${PRODUCTION}" &>> "${logFile}"
  fi
}

# Get the stats for this git author, just for fun
function gitStats() {
  if [[ "${GITSTATS}" == "TRUE" ]] && [[ "${QUIET}" != "1" ]] && [[ "${PUBLISH}" != "1" ]] && [[ "${APPROVE}" != "1" ]]; then
    console "Calculating..."
    getent passwd "${USER}" | cut -d ':' -f 5 | cut -d ',' -f 1 > "${trshFile}"
    FULLUSER=$(<"${trshFile}")
    git log --author="${FULLUSER}" --pretty=tformat: --numstat | \
    # The single quotes were messing with trying to line break this one
    awk '{ add += $1 ; subs += $2 ; loc += $1 - $2 } END { printf "Your total lines of code contributed so far: %s\n(+%s added | -%s deleted)\n",loc,add,subs }' -
  fi
} 
