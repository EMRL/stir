#!/usr/bin/env bash
#
# utilities.sh
#
###############################################################################
# Handles various setup, logging, and option flags
###############################################################################
trace "Loading utilities"

# Initialize variables
read -r integer_check <<< ""
echo "${integer_check}" > /dev/null

# Open a deployment session, ask for user confirmation before beginning
function go() {
  if [[ "${QUIET}" != "1" ]]; then
    tput cnorm;
  fi

  # Get some project data for the logs; we only want to get server monitor 
  # info if we're not running a monitor test since we already loaded the 
  # password file contents into a variable
  if [[ "${MONITORTEST}" != "1" ]]; then
    server_monitor
  fi
  scan_check
  check_backup

  console "deploy ${VERSION}"

  # Build only
  if [[ "${BUILD}" == "1" ]]; then
    pkgMgr; quietExit
  fi  

  if [[ "${INCOGNITO}" != "TRUE" ]]; then
    console "Current working path is ${WORKPATH}/${APP}"
  fi
  
  # Slack test
  if [[ "${SLACKTEST}" == "1" ]]; then
    slackTest; quickExit
  fi

  # Webhook POST test
  if [[ "${POSTTEST}" == "1" ]]; then
    postTest; quickExit
  fi

  # Email test
  if [[ "${EMAILTEST}" == "1" ]]; then
    email_test; quickExit
  fi

  # Test analytics authentication
  if [[ "${ANALYTICSTEST}" == "1" ]]; then
    ga_test; quickExit
  fi

  # Test server monitoring
  if [[ "${MONITORTEST}" == "1" ]]; then
    server_monitor_test; quickExit
  fi

  # Test analytics authentication
  if [[ "${CHECK_BACKUP}" == "1" ]]; then
    check_backup; quickExit
  fi

  # Test SSH key authentication using the --ssh-check flag
  if [[ "${SSHTEST}" == "1" ]]; then
    if [[ "${NOKEY}" != "TRUE" ]] && [[ "${DISABLESSHCHECK}" != "TRUE" ]]; then
      notice "Checking SSH Configuration..."
      ssh_check
    else
      warning "This project is not configured to use SSH keys, no check needed."
    fi
    quickExit
  fi

  # Generate git stats
  if [[ "${PROJSTATS}" == "1" ]]; then
    project_stats; quickExit
  fi

  # Chill and wait for user to confirm project
  if  [[ "${FORCE}" == "1" || "${SCAN}" == "1" || "${PROJSTATS}" == "1" ]] || yesno --default yes "Continue? [Y/n] "; then
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

  # Disallow server check?
  if [[ "${NOCHECK}" == "1" ]]; then
    SERVERCHECK="FALSE";
    ACTIVECHECK="FALSE"
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

function fix_index() {
  # A rather brutal fix for index permissions issues
  if [[ "${FIXINDEX}" == "TRUE" ]]; then
    if [[ ! -w "${WORKPATH}/${APP}/.git/index" ]]; then
      trace "Index is not writable, attempting to fix..."
      sudo chmod 777 "${WORKPATH}/${APP}/.git/index"; error_check
      if [[ ! -w "${WORKPATH}/${APP}/.git/index" ]]; then
        error "Unable to write new index file."
      fi
    fi
    sleep 1
  fi
}

# Check that a variable is an integer
function is_integer() {
  declare arg1="$1"; integer_check="0"
  if [[ ! "${arg1}" =~ ^[0-9]+$ ]] ; then
    integer_check="1"
  fi
}


# Check that dependencies exist
function dependency_check() {
  # Is git installed?
  hash git 2>/dev/null || {
    error "deploy ${VERSION} requires git to function properly." 
  }

  # Does a configuration file for this repo exist?
  if [[ -z "${APPRC}" ]]; then
    # Make sure app directory is writable
    if [[ -w "${WORKPATH}/${APP}" ]]; then
      empty_line; info "Project configuration not found, creating."; sleep 2
      # If configuration directory is defined
      if [[ -n "${CONFIGDIR}" ]]; then
        if [[ ! -d "${WORKPATH}/${APP}/${CONFIGDIR}" ]]; then
          mkdir "${WORKPATH}/${APP}/${CONFIGDIR}"
        fi
        cp "${deployPath}"/deploy.sh "${WORKPATH}/${APP}/${CONFIGDIR}/"
        APPRC="${WORKPATH}/${APP}/${CONFIGDIR}/deploy.sh"
      else
        # If using root directory for .deploy.sh
        cp "${deployPath}"/deploy.sh "${WORKPATH}/${APP}/.deploy.sh"
        APPRC="${WORKPATH}/${APP}/.deploy.sh"
      fi
      # Ask the user if they would like to edit
      if [[ -x "$(command -v nano)" ]]; then
        if yesno --default yes "Would you like to edit the configuration file now? [Y/n] "; then
          nano "${APPRC}"
          clear; sleep 1
          $(basename ${APP}) && exit
          # exec "/usr/local/bin/deploy ${STARTUP} ${APP}"
        fi
        info "You can change configuration later by editing ${APPRC}"
      fi
    else
      # Error out if directory is not writable
      error "Project directory is not writable."
    fi
  fi
  
  # If a deploy command is declared, check that it actually exists.
  # This is probably not the best way to do this but for now it works. It 
  # strips everything after the first space that is declared in DEPLOY and
  # then checks that it's a valid command.
  if [[ ! -z "${DEPLOY}" ]] && [[ "${DEPLOY}" != "SCP" ]]; then
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
