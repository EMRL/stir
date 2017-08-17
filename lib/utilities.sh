#!/bin/bash
#
# utilities.sh
#
###############################################################################
# Handles various setup, logging, and option flags
###############################################################################
trace "Loading utilities"

# Open a deployment session, ask for user confirmation before beginning
function go() {
  if [[ "${QUIET}" != "1" ]]; then
    tput cnorm;
  fi
  console "deploy ${VERSION}"
  console "Current working path is ${WORKPATH}/${APP}"

  # Slack test
  if [[ "${SLACKTEST}" == "1" ]]; then
    slackTest; quickExit
  fi

  # Email test
  if [[ "${EMAILTEST}" == "1" ]]; then
    emailTest; quickExit
  fi

  # Test analytics authentication
  if [[ "${ANALYTICSTEST}" == "1" ]]; then
    analyticsTest; quickExit
  fi

  # Test SSH key authentication
  if [[ "${SSHTEST}" == "1" ]]; then
    if [[ "${NOKEY}" != "TRUE" ]]; then
      notice "Checking SSH Configuration..."
      sshChk
    else
      warning "This project is not configured to use SSH keys, no check needed."
    fi
    quickExit
  fi

  # Generate git stats
  if [[ "${PROJSTATS}" == "1" ]]; then
    projStats; quickExit
  fi

  # Chill and wait for user to confirm project
  if  [[ "${FORCE}" == "1" ]] || yesno --default yes "Continue? [Y/n] "; then
    trace "Loading project"
  else
    quickExit
  fi

  # Is this project locked?
  if [[ "${DONOTDEPLOY}" == "TRUE" ]]; then
    warning "This project is currently locked, and can't be deployed."; quickExit
  fi

  # Is the user root?
  if [[ "${ALLOWROOT}" != "TRUE" ]] && [[ "${EUID}" -eq "0" ]]; then
    warning "Can't continue deployment as root."; quickExit
  fi

  # Force sudo password input if needed
  if [[ "${FIXPERMISSIONS}" == "TRUE" ]]; then
    sudo sleep 1
  fi

  # if git.lock exists, do we want to remove it?
  if [[ -f "${gitLock}" ]]; then
    warning "Found ${gitLock}"
    # If running in --force mode we will not allow deployment to continue
    if [[ "${FORCE}" = "1" ]]; then
      warning "Can't continue deployment using --force."; quietExit
    else
      if yesno --default no "Remove lockfile? [y/N] "; then
        rm -f "${gitLock}" 2>/dev/null
        sleep 1
      else
        quickExit
      fi
    fi
  fi
  
  # Outstanding approval?
  if [[ "${REQUIREAPPROVAL}" == "TRUE" ]] && [[ -f "${WORKPATH}/${APP}/.queued" ]] && [[ -f "${WORKPATH}/${APP}/.approved" ]]; then 
    notice "Processing outstanding approval..."
  fi
}

function fixIndex() {
  # A rather brutal fix for index permissions issues
  if [[ "${FIXINDEX}" == "TRUE" ]]; then
    if [[ ! -w "${WORKPATH}/${APP}/.git/index" ]]; then
      trace "Index is not writable, attempting to fix..."
      sudo chmod 777 "${WORKPATH}/${APP}/.git/index"; errorChk
      if [[ ! -w "${WORKPATH}/${APP}/.git/index" ]]; then
        error "Unable to write new index file."; 
      fi
    fi
    sleep 1
  fi
}

# Check that dependencies exist
function depCheck() {
  # Is git installed?
  hash git 2>/dev/null || {
    error "deploy ${VERSION} requires git to function properly." 
  }

  # Does a configuration file for this repo exist?
  if [[ -z "${APPRC}" ]]; then
    if [[ ! -d "${WORKPATH}/${APP}/${CONFIGDIR}" ]]; then
      mkdir "${WORKPATH}/${APP}/${CONFIGDIR}"
    fi
    emptyLine; info "Project configuration not found, creating."; sleep 2
    cp "${deployPath}"/deploy.sh "${WORKPATH}/${APP}/${CONFIGDIR}/"
    if yesno --default yes "Would you like to edit the configuration file now? [Y/n] "; then
      nano "${WORKPATH}/${APP}/${CONFIGDIR}/deploy.sh"
      clear; sleep 1
      quickExit
    else
      info "You can change configuration later by editing ${WORKPATH}/${APP}/${CONFIGDIR}/deploy.sh"
    fi
  fi
  
  # If a deploy command is declared, check that it actually exists.
  # This is probably not the best way to do this but for now it works. It 
  # strips everything after the first space that is declared in DEPLOY and
  # then checks that it's a valid command.
  if [[ ! -z "${DEPLOY}" ]]; then
    deploy_cmd=$(echo "$DEPLOY" | head -n1 | awk '{print $1;}')
    hash "${deploy_cmd}" 2>/dev/null || { 
      error >&2 "Unknown deployment command: ${DEPLOY} (${deploy_cmd} not found)"; 
    }
  fi

  # Do we need Sendmail, and if so can we find it?
  if [[ "${EMAILERROR}" == "TRUE" ]] || [[ "${EMAILSUCCESS}" == "TRUE" ]] || [[ "${EMAILQUIT}" == "TRUE" ]] || [[ "${NOTIFYCLIENT}" == "TRUE" ]]; then
    hash "${MAILPATH}"/sendmail 2>/dev/null || {
      error "deploy ${VERSION} requires Sendmail to function properly with your current configuration."
    }
  fi
}
