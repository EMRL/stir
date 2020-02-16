#!/usr/bin/env bash
#
# utilities.sh
#
###############################################################################
# Handles various setup, logging, and option flags
###############################################################################

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

  console "stir ${VERSION}"

  # Build only
  if [[ "${BUILD}" == "1" ]]; then
    pkgMgr; quietExit
  fi  

  if [[ "${INCOGNITO}" != "TRUE" ]]; then
    console "Current working path is ${APP_PATH}"
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
  if [[ "${DONOTDEPLOY}" == "TRUE" ]] || [[ -f "${WORKPATH}/${APP}/.donotdeploy" ]]; then
    warning "This project is currently locked, and can't be deployed."; quickExit
  fi

  # Is the user root?
  if [[ "${ALLOWROOT}" != "TRUE" ]] && [[ "${EUID}" -eq "0" ]]; then
    warning "Can't continue as root."; quickExit
  fi

  # Disallow server check?
  if [[ "${NOCHECK}" == "1" ]]; then
    SERVERCHECK="FALSE";
    ACTIVECHECK="FALSE"
  fi

  # if git.lock exists, do we want to remove it?
  if [[ -f "${gitLock}" ]]; then
    warning "Found ${gitLock}"
    # If running in --force mode we will not allow deployment to continue
    if [[ "${FORCE}" = "1" ]]; then
      warning "Can't continue using --force."; quietExit
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

# Check that a variable is an integer
function is_integer() {
  declare arg1="$1"; integer_check="0"
  if [[ ! "${arg1}" =~ ^[0-9]+$ ]] ; then
    integer_check="1"
  fi
}

function get_fullpath() {
  # Get absolute paths to critical commands
  var=(composer wp sendmail wget curl git mysqlshow grep wc)

  for i in "${var[@]}" ; do
    read -r "${i}_cmd" <<< ""
    echo "${i}_cmd" > /dev/null
    if [[ -x "$(command -v ${i})" ]]; then
      eval "${i}_cmd=\"$(which ${i})\""
    fi
  done

  # What is this I don't even
  wp_cmd="$(which wp)"
}

# User tests
function user_tests() {
  if [[ "${SHOWSETTINGS}" == "1" ]]; then
    show_settings; quickExit
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
}

# Check that dependencies exist
function dependency_check() {
  # Is git installed?
  hash git 2>/dev/null || {
    error "stir ${VERSION} requires git to function properly." 
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
    hash "${sendmail_cmd}" 2>/dev/null || {
      error "stir ${VERSION} requires Sendmail to function properly with your current configuration."
    }
  fi
}

function show_settings() {
  notice "General Setup"
  echo "-------------"
  [[ -n "${WORKPATH}" ]] && echo "Root project storage: ${WORKPATH}"
  [[ -n "${REPOHOST}" ]] && echo "Repohost: ${REPOHOST}"
  [[ -n "${SERVERCHECK}" ]] && echo "Server checking: ${SERVERCHECK}"
  [[ -n "${ALLOWROOT}" ]] && echo "Allow superuser: ${ALLOWROOT}"
  [[ -n "${ACTIVECHECK}" ]] && echo "Check file activity: ${ACTIVECHECK}"  
  [[ -n "${CHECKTIME}" ]] && echo "Active time limit: ${CHECKTIME} minutes"
  # Project
  notice "Project Information"
  echo "-------------------"
  [[ -n "${PROJNAME}" ]] && echo "Name: ${PROJNAME}"
  [[ -n "${PROJCLIENT}" ]] && echo "Client: ${PROJCLIENT}"
  [[ -n "${DEVURL}" ]] && echo "Staging URL: ${DEVURL}"
  [[ -n "${PRODURL}" ]] && echo "Production URL: ${PRODURL}"
  # Git
  if [[ -n "${REPO}" ]] || [[ -n "${MASTER}" ]] || [[ -n "${PRODUCTION}" ]] || [[ -n "${AUTOMERGE}" ]] || [[ -n "${STASH}" ]] || [[ -n "${CHECKBRANCH}" ]]; then
    notice "Git Configuration"
    echo "-----------------"
    [[ -n "${REPO}" ]] && echo "Repo URL: ${REPOHOST}/${REPO}"
    [[ -n "${REPO}" ]] && echo "Local repo path: ${APP_PATH}"
    [[ -n "${MASTER}" ]] && echo "Master branch: ${MASTER}"
    [[ -n "${PRODUCTION}" ]] && echo "Production branch: ${PRODUCTION}"
    [[ -n "${AUTOMERGE}" ]] && echo "Auto merge: ${AUTOMERGE}"
    [[ -n "${STASH}" ]] && echo "File Stashing: ${STASH}"
    [[ -n "${CHECKBRANCH}" ]] && echo "Force branch checking: ${CHECKBRANCH}" 
  fi
  # Wordpress
  if [[ -n "${WPROOT}" ]] || [[ -n "${WPAPP}" ]] || [[ -n "${WPSYSTEM}" ]]; then
    notice "Wordpress Setup"
    echo "---------------"
    [[ -n "${WPROOT}" ]] && echo "Wordpress root: ${WPROOT}"
    [[ -n "${WPAPP}" ]] && echo "Wordpress application: ${WPAPP}"
    [[ -n "${WPSYSTEM}" ]] && echo "Wordpress system: ${WPSYSTEM}"
  fi
  # Deployment
  if [[ -n "${DEPLOY}" ]] || [[ -n "${DONOTDEPLOY}" ]]; then
    notice "Deployment Configuration"
    echo "------------------------"
    [[ -n "${DEPLOY}" ]] && echo "Deploy command: ${DEPLOY}"
    [[ -n "${DONOTDEPLOY}" ]] && echo "Disallow deployment: ${DONOTDEPLOY}"
  fi
  # Notifications
  if [[ -n "${TASK}" ]] || [[ -n "${TASKUSER}" ]] || [[ -n "${ADDTIME}" ]] || [[ -n "${POSTTOSLACK}" ]] || [[ -n "${SLACKERROR}" ]] || [[ -n "${PROFILEID}" ]] || [[ -n "${POSTURL}" ]]; then
    notice "Notifications"
    echo "-------------"
    [[ -n "${TASK}" ]] && echo "Task #: ${TASK}"
    [[ -n "${TASKUSER}" ]] && echo "Task user: ${TASKUSER}"
    [[ -n "${ADDTIME}" ]] && echo "Task time: ${ADDTIME}"
    [[ -n "${POSTTOSLACK}" ]] && echo "Post to Slack: ${POSTTOSLACK}"
    [[ -n "${SLACKERROR}" ]] && echo "Post errors to Slack: ${SLACKERROR}"
    [[ -n "${POSTURL}" ]] && echo "Webhook URL: ${POSTURL}"
    [[ -n "${PROFILEID}" ]] && echo "Google Analytics ID: ${PROFILEID}"
  fi
  # Logging
  if [[ -n "${REMOTELOG}" ]] || [[ -n "${REMOTEURL}" ]] || [[ -n "${EXPIRELOGS}" ]] || [[ -n "${LOCALHOSTPOST}" ]] || [[ -n "${LOCALHOSTPATH}" ]] || [[ -n "${SCPPOST}" ]] || [[ -n "${SCPUSER}" ]] || [[ -n "${SCPHOST}" ]] || [[ -n "${SCPHOSTPATH}" ]] || [[ -n "${SCPPASS}" ]] || [[ -n "${REMOTETEMPLATE}" ]] || [[ -n "${REMOTETEMPLATE}" ]]; then
    notice "Logging"
    echo "-------"
    [[ -n "${TO}" ]] && echo "Send to: ${TO}"
    [[ -n "${HTMLTEMPLATE}" ]] && echo "Email template: ${HTMLTEMPLATE}"
    [[ -n "${CLIENTLOGO}" ]] && echo "Logo: ${CLIENTLOGO}"
    [[ -n "${COVER}" ]] && echo "Cover image: ${COVER}"
    [[ -n "${INCOGNITO}" ]] && echo "Logo: ${INCOGNITO}"
    [[ -n "${REMOTELOG}" ]] && echo "Web logs: ${REMOTELOG}"
    [[ -n "${REMOTEURL}" ]] && echo "Address: ${REMOTEURL}"
    [[ -n "${EXPIRELOGS}" ]] && echo "Log expiration: ${EXPIRELOGS} days"
    [[ -n "${REMOTETEMPLATE}" ]] && echo "Log template: ${REMOTETEMPLATE}"
    [[ -n "${SCPPOST}" ]] && echo "Post with SCP/SSH: ${SCPPOST}"
    [[ -n "${SCPUSER}" ]] && echo "SCP user: ${SCPUSER}"
    [[ -n "${SCPHOST}" ]] && echo "Remote log host: ${SCPHOST}"
    [[ -n "${SCPHOSTPATH}" ]] && echo "Remote log path: ${SCPHOSTPATH}"
    [[ -n "${SCPHOSTPORT}" ]] && echo "Remote log path: ${SCPHOSTPORT}"
    [[ -n "${LOCALHOSTPOST}" ]] && echo "Save logs locally: ${LOCALHOSTPOST}"
    [[ -n "${LOCALHOSTPATH}" ]] && echo "Path to local logs: ${}LOCALHOSTPATH"
  fi
  # Weekly Digests
  if [[ -n "${DIGESTEMAIL}" ]]; then
    notice "Weekly Digests"
    echo "--------------"
    [[ -n "${DIGESTEMAIL}" ]] && echo "Send to: ${DIGESTEMAIL}"
  fi
  # Monthly Reporting
  if [[ -n "${CLIENTCONTACT}" ]] || [[ -n "${INCLUDEHOSTING}" ]]; then
    notice "Monthly Reporting"
    echo "-----------------"
    [[ -n "${CLIENTCONTACT}" ]] && echo "Client contact: ${CLIENTCONTACT}"
    [[ -n "${INCLUDEHOSTING}" ]] && echo "Hosting notes: ${INCLUDEHOSTING}"
  fi
  # Invoice Ninja integration
  if [[ -n "${IN_HOST}" ]] || [[ -n "${IN_TOKEN}" ]] || [[ -n "${IN_CLIENT_ID}" ]] || [[ -n "${IN_PRODUCT}" ]] || [[ -n "${IN_ITEM_COST}" ]] || [[ -n "${IN_ITEM_QTY}" ]] || [[ -n "${IN_NOTES}" ]] || [[ -n "${IN_NOTES}" ]]; then
    notice "Invoice Ninja Integration"
    echo "-------------------------"
    [[ -n "${IN_HOST}" ]] && echo "Host: ${IN_HOST}"
    [[ -n "${IN_TOKEN}" ]] && echo "Token: ${IN_TOKEN}"
    [[ -n "${IN_CLIENT_ID}" ]] && echo "Client ID: ${IN_CLIENT_ID}"
    [[ -n "${IN_PRODUCT}" ]] && echo "Product: ${IN_PRODUCT}"
    [[ -n "${IN_ITEM_COST}" ]] && echo "Item cost: ${IN_ITEM_COST}"
    [[ -n "${IN_ITEM_QTY}" ]] && echo "Item quantity: ${IN_ITEM_QTY}"
    [[ -n "${IN_NOTES}" ]] && echo "Notes: ${IN_NOTES}"
  fi
  # Google Analytics
  if [[ -n "${CLIENTID}" ]] || [[ -n "${CLIENTSECRET}" ]] || [[ -n "${REDIRECTURI}" ]] || [[ -n "${AUTHORIZATIONCODE}" ]] || [[ -n "${ACCESSTOKEN}" ]] || [[ -n "${REFRESHTOKEN}" ]] || [[ -n "${PROFILEID}" ]]; then
    notice "Google Analytics"
    echo "----------------"
    [[ -n "${CLIENTID}" ]] && echo "Client ID: ${CLIENTID}"
    [[ -n "${CLIENTSECRET}" ]] && echo "Client secret: ${CLIENTSECRET}"
    [[ -n "${REDIRECTURI}" ]] && echo "Redirect URI: ${REDIRECTURI}"
    [[ -n "${AUTHORIZATIONCODE}" ]] && echo "Authorization code: ${AUTHORIZATIONCODE}"
    [[ -n "${ACCESSTOKEN}" ]] && echo "Access token: ${ACCESSTOKEN}"
    [[ -n "${REFRESHTOKEN}" ]] && echo "Refresh token: ${REFRESHTOKEN}"
    [[ -n "${PROFILEID}" ]] && echo "Profile ID: ${PROFILEID}"
  fi
  # Server monitoring
  if [[ -n "${MONITORURL}" ]] || [[ -n "${MONITORUSER}" ]] || [[ -n "${SERVERID}" ]]; then
    notice "Server Monitoring"
    echo "-----------------"
    [[ -n "${MONITORURL}" ]] && echo "Monitor URL: ${MONITORURL}"
    [[ -n "${MONITORUSER}" ]] && echo "User: ${MONITORUSER}"
    [[ -n "${SERVERID}" ]] && echo "Server ID: ${SERVERID}"
  fi
  # Dropbox integration
  if [[ -n "${DB_API_TOKEN}" ]] || [[ -n "${DB_BACKUP_PATH}" ]]; then
    notice "Dropbox Integration"
    echo "-------------------"
    [[ -n "${DB_API_TOKEN}" ]] && echo "Token: ${DB_API_TOKEN}"
    [[ -n "${DB_BACKUP_PATH}" ]] && echo "Backup path: ${DB_BACKUP_PATH}"
  fi
  # Malware scanning
  if [[ -n "${NIKTO}" ]] || [[ -n "${NIKTO_CONFIG}" ]] || [[ -n "${NIKTO_PROXY}" ]]; then
    notice "Malware Scanning"
    echo "----------------"
    [[ -n "${NIKTO}" ]] && echo "Scanner: ${NIKTO}"
    [[ -n "${NIKTO_CONFIG}" ]] && echo "Configuration path: ${NIKTO_CONFIG}"
    [[ -n "${NIKTO_PROXY}" ]] && echo "Proxy: ${NIKTO_PROXY}"
  fi
  empty_line

  if [[ -n "${TO}" ]]; then
    if [[ "${CURRENT}" == "1" ]]; then
      console "You can email this information to yourself by using 'stir --test-email --current'"
      else
      console "You can email this information to yourself by using 'stir --test-email ${APP}'"
    fi
  fi      
  quickExit
}
