#!/usr/bin/env bash
#
# git-obj.sh
#
###############################################################################
# Functions related to handling files and branches
###############################################################################

# Initialize variables
var=(working_branch full_user src_branch dest_branch)
init_loop

# Assign a variable to represent .git/index.lock
git_lock="${APP_PATH}/.git/index.lock"

function verify_project() {
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

  # Return if this is not a git project
  if [[ "${SKIP_GIT}" -eq "1" ]]; then
    return
  fi

  # Check that .git exists
  if [[ -f "${APP_PATH}/.git/index" ]]; then
    sleep 1
  else
    info "There is no working project at ${APP_PATH}"
    clean_up; exit 51
  fi

  # Make sure master is defined
  if [[ -z "${MASTER}" ]]; then
    empty_line; error "stir ${VERSION} requires a master branch to be defined.";
  fi

  # Make sure there has been at least one commit previously made
  git rev-parse --abbrev-ref HEAD &>> "${trash_file}"
  if grep -aq "fatal" "${trash_file}"; then 
    error "Unable to start, push your first commit manually and try again."
  else  
    # If running --automate, force a branch check
    if [[ "${AUTOMATE}" == "1" ]]; then
      CHECK_BRANCH="${MASTER}"
    fi
    # If CHECK_BRANCH is set, make sure current branch is correct.
    start_branch="$(git rev-parse --abbrev-ref HEAD)"
    if [[ -n "${CHECK_BRANCH}" ]] && [[ "${DIGEST}" != "1" ]] && [[ "${PROJSTATS}" != "1" ]] && [[ "${TEST_EMAIL}" != "1" ]] && [[ "${TEST_SLACK}" != "1" ]]; then 
      if [[ "${start_branch}" != "${CHECK_BRANCH}" ]]; then
        error "Must be on ${CHECK_BRANCH} branch to continue.";
      fi
    fi
  fi

  # Check for active files
  check_active

  # If running --automate, pull and sync all branches
  if [[ "${AUTOMATE}" == "1" ]]; then
    trace "Syncing with origin"
    "${git_cmd}" fetch --all &>> "${log_file}"; error_check
    sleep 2 # Chill for a second (or 2 :p)
    "${git_cmd}" pull --all &>> "${log_file}"; error_check
  fi

  # Try to clear out old git processes owned by this user, if they exist
  pkill -f git &>> /dev/null || true
}

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
      git checkout "${working_branch}" | tee --append "${log_file}"
    else
      if [[ "${QUIET}" != "1" ]]; then
        git checkout "${working_branch}" &>> "${log_file}" &
        show_progress
      else
        git checkout "${working_branch}" &>> "${log_file}"
      fi
    fi
  fi
}

# Does anything need to be committed? (Besides me?)
function status() {
  if [[ -z "$(git status --porcelain)" ]]; then
    if [[ "${APPROVE}" != "1" ]] && [[ "${DENY}" != "1" ]]; then
      if [[ "${REQUIRE_APPROVAL}" == "TRUE" ]]; then
        console "Nothing to queue, working directory clean."
      else
        console "Nothing to commit, working directory clean."
      fi
      quiet_exit
    fi
  fi
}

# Stage files
function stage() {
  # Check for stuff that needs a commit
  if [[ -z $(git status --porcelain) ]]; then
    console "Nothing to commit, working directory clean."; quiet_exit
  else
    empty_line
    if [[ "${FORCE}" = "1" ]] || yesno --default yes "Stage files? [Y/n] "; then
      trace "Staging files"
      if [[ "${VERBOSE}" == "TRUE" ]]; then
        git add --all :/ | tee --append "${log_file}"; error_check              
      else  
        git add --all :/ &>> "${log_file}"; error_check
      fi
    else
      trace "Exiting without staging files"; user_exit    
    fi
  fi
}

# TODO: REWRITE
function push() {
  trace "Push ${working_branch}";
  empty_line
  if [[ "${VERBOSE}" == "TRUE" ]]; then
    git push origin "${working_branch}" | tee --append "${log_file}"; error_check 
    trace "OK"              
  else
    if [[ "${FORCE}" = "1" ]] || yesno --default yes "Push ${working_branch} branch? [Y/n] "; then
      if [[ "${QUIET}" != "1" ]]; then
        sleep 1
        git push origin "${working_branch}" &>> "${log_file}" &
        spinner $!
        info "Success.    "
      else
        git push origin "${working_branch}" &>> "${log_file}"; error_check
      fi
      sleep 1
      if [[ "$(git status --porcelain)" ]]; then
        sleep 1; git add --all :/ &>> "${log_file}"
        git push --force-with-lease  &>> "${log_file}"
      fi
    else
      clean_exit
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
    [[ -f "${git_lock}" ]] && rm "${git_lock}"
    if [[ "${VERBOSE}" == "TRUE" ]]; then
      git merge "${MASTER}" | tee --append "${log_file}"              
    else
      if [[ "${QUIET}" != "1" ]]; then
        # git merge --no-edit master &>> "${log_file}" &
        git merge "${MASTER}" &>> "${log_file}" &
        show_progress
      else
        git merge "${MASTER}" &>> "${log_file}"
      fi
    fi
  fi
}

###############################################################################
# confirm_branch()
#   Makes sure the current branch is the correct branch
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
        [[ -f "${git_lock}" ]] && rm "${git_lock}"
        git checkout "${working_branch}" &>> "${log_file}" #; error_check
      fi
    else
      clean_exit
    fi
    # Were there any conflicts checking out?
    if grep -aq "error: Your local changes to the following files would be overwritten by checkout:" "${log_file}"; then
      error "There is a conflict checking out."
    else
      trace "OK"
    fi 
  fi
}

# Commit, with message
function commit() {
  # Smart commit stuff
  smart_commit; empty_line

  # Do a dry run; check for anything to commit
  git commit --dry-run &>> "${log_file}" 

  if grep -aq "nothing to commit, working directory clean" "${log_file}"; then 
    info "Nothing to commit, working directory clean."
    clean_exit
  else
    # Found stuff, let's get a commit message
    if [[ -z "${commit_message}" ]]; then
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
        if [[ "${SMART_COMMIT}" -ne "TRUE" ]]; then
          console "Smart Commits must be enabled when forcing updates."
          console "Set SMART_COMMIT=TRUE in .stir.sh"; quiet_exit
        else
          if [[ -z "${commit_message}" ]]; then
            info "Commit message must not be empty."; quiet_exit
          else
            notes="${commit_message}"
          fi
        fi
      else
        # We want to be able to edit the default commit if available
        if [[ "${FORCE}" != "1" ]]; then
          notes="${commit_message}"
          read -rp "Edit commit message: " -e -i "${commit_message}" notes
          # Update the commit message based on user input ()
          notes="${notes:-$commit_message}"
        else
          info "Using auto-generated commit message: ${commit_message}"
          notes="${commit_message}"
        fi
      fi
    fi

    if [[ "${REQUIRE_APPROVAL}" == "TRUE" ]] && [[ "${APPROVE}" != "1" ]] && [[ "${DENY}" != "1" ]]; then 
      trace "Queuing commit message"
      echo "${notes}" > "${WORK_PATH}/${APP}/.queued"
    else
      git commit -m "${notes}" &>> "${log_file}"; error_check
      trace "Commit message: ${notes}"
    fi
  fi

  # Check for bad characters in commit message
  echo "${notes}" > "${trash_file}"
  sed -i "s/\&/and/g" "${trash_file}"
  notes=$(<$trash_file)
}

# Garbage collection
function garbage() {
  if [[ "${GARBAGE}" = "TRUE" ]] && [[ "${QUIET}" != "1" ]]; then 
    notice "Preparing project files..."
    git gc | tee --append "${log_file}"
    if [[ "${QUIET}" != "1" ]]; then
      git gc &>> "${log_file}"
    fi
  fi
}

# Get the stats for this git author, just for fun
function git_stats() {
  if [[ "${GIT_STATS}" == "TRUE" ]] && [[ "${QUIET}" != "1" ]] && [[ "${PUBLISH}" != "1" ]] && [[ "${APPROVE}" != "1" ]]; then
    console "Calculating..."
    getent passwd "${USER}" | cut -d ':' -f 5 | cut -d ',' -f 1 > "${trash_file}"
    full_user=$(<"${trash_file}")
    git log --author="${full_user}" --pretty=tformat: --numstat | \
    # The single quotes were messing with trying to line break this one
    awk '{ add += $1 ; subs += $2 ; loc += $1 - $2 } END { printf "Your total lines of code contributed so far: %s\n(+%s added | -%s deleted)\n",loc,add,subs }' -
  fi
}

# Get info about the git repository
function git_info() {
  # git config --get remote.origin.url returns result like git@github.com:EMRL/stir.git
  # git rev-parse --show-toplevel returns path to project

  # Get repo name
  REPO=$(git config --get remote.origin.url | sed 's@.*/@@'); REPO="${REPO//.git}"

  # Get repo URL
  REPO_HOST=$(git config --get remote.origin.url | sed -e 's@.*\@@@' -e 's^:^/^g' \
    -e 's@^@https://@'); REPO_HOST="${REPO_HOST//.git}"

}
