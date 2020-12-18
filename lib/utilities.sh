#!/usr/bin/env bash
#
# utilities.sh
#
###############################################################################
# Handles various setup, logging, and option flags
###############################################################################

# Initialize variables
var=(integer_check json_key json_num)
init_loop

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
    build_check; quiet_exit
  fi  

  if [[ "${INCOGNITO}" != "TRUE" ]]; then
    console "Current working path is ${APP_PATH}"
  fi

  # Generate git stats
  if [[ "${PROJSTATS}" == "1" ]]; then
    project_stats; quiet_exit
  fi

  # Chill and wait for user to confirm project
  if  [[ "${FORCE}" == "1" || "${SCAN}" == "1" || "${PROJSTATS}" == "1" ]] || yesno --default yes "Continue? [Y/n] "; then
    trace "Loading project"
  else
    quiet_exit
  fi

  # Is this project locked?
  if [[ "${DONOTDEPLOY}" == "TRUE" ]]; then
    warning "This project is currently locked."; quiet_exit
  fi

  # Is the user root?
  if [[ "${ALLOWROOT}" != "TRUE" ]] && [[ "${EUID}" -eq "0" ]]; then
    warning "Can't continue as root."; quiet_exit
  fi

  # Disallow server check?
  if [[ "${NOCHECK}" == "1" ]]; then
    SERVERCHECK="FALSE";
    ACTIVECHECK="FALSE"
  fi

  # if git.lock exists, do we want to remove it?
  if [[ -f "${git_lock}" ]]; then
    warning "Found ${git_lock}"
    # If running in --force mode we will not allow deployment to continue
    if [[ "${FORCE}" = "1" ]]; then
      warning "Can't continue using --force."; quiet_exit
    else
      if yesno --default no "Remove lockfile? [y/N] "; then
        rm -f "${git_lock}" 2>/dev/null
        sleep 1
      else
        quiet_exit
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
  declare arg1="${1}"; integer_check="0"
  if [[ ! "${arg1}" =~ ^[0-9]+$ ]] ; then
    integer_check="1"
  fi
}

function get_fullpath() {
  # Get absolute paths to critical commands
  var=(cal composer curl git gitchart gnuplot grep grunt mysqlshow npm scp 
    sendmail ssh sshpass ssmtp unzip wc wget wkhtmltopdf wp xmlstarlet)
  for i in "${var[@]}" ; do
    read -r "${i}_cmd" <<< ""
    echo "${i}_cmd" > /dev/null
    if [[ -x "$(command -v ${i})" ]]; then
      eval "${i}_cmd=\"$(which ${i})\""
    fi
  done

  # If the user has SMTP configured, overwrite sendmail command with ssmtp
  check_smtp

  # What is this I don't even
  wp_cmd="$(which wp)"
}

###############################################################################
# strip_empty_variables()
#   A simple function to handle git checkouts
#
# Arguments:
#   [file]    The file in which to strip out {{UNUSED_VARIABLE}}
###############################################################################
function strip_empty_variables() {
  sudo sed -i 's^{{.*}}^^g' "${1}"
}

###############################################################################
# get_json_value()
#   Get a value (or values) from a json file
#
# Arguments:
#   [key]         The JSON key whose value you are after
#   [occurance]   Get the value of the nth occurance of the key
#
# Example use:
#   get_json_value name
#   get_json_value name 30
#   cat tmpfile.txt | get_json_value id
#   VARIABLE="$(cat tmpfile.txt | get_json_value id 7)"
############################################################################### 
function get_json_value() {
  if [[ -n ${1} ]]; then
      json_key="${1}"
      json_num="${2}"
      awk -F"[,:}]" '{for(i=1;i<=NF;i++){if($i~/'${json_key}'\042/){print $(i+1)}}}' | tr -d '"' | sed -n "${json_num}"p
  fi
}

###############################################################################
# set_fallback_values()
#   Set defaults for things liks SSH ports if missing
###############################################################################
function set_fallback_values() {
  [[ -z "${SCPPORT}" ]] && SCPPORT="22"
  [[ -z "${SCP_DEPLOY_PORT}" ]] && SCP_DEPLOY_PORT="22"
}

# User tests
function user_tests() {
  if [[ "${SHOW_SETTINGS}" == "1" ]]; then
    show_settings; quiet_exit
  fi

  # Slack test
  if [[ "${SLACKTEST}" == "1" ]]; then
    slack_test; quiet_exit
  fi

  # Webhook POST test
  if [[ "${test_webhook}" == "1" ]]; then
    test_webhook; quiet_exit
  fi

  # Email test
  if [[ "${EMAILTEST}" == "1" ]]; then
    email_test; quiet_exit
  fi

  # Test analytics authentication
  if [[ "${ANALYTICSTEST}" == "1" ]]; then
    ga_test; quiet_exit
  fi

  # Test server monitoring
  if [[ "${MONITORTEST}" == "1" ]]; then
    server_monitor_test; quiet_exit
  fi

  # Test Bugsnag integration
  if [[ "${test_bugsnag}" == "1" ]]; then
    test_bugsnag; quiet_exit
  fi

  # Test Dropbox backup authentication
  if [[ "${CHECK_BACKUP}" == "1" ]]; then
    check_backup; quiet_exit
  fi

  # Test SSH key authentication using the --ssh-check flag
  if [[ "${SSHTEST}" == "1" ]]; then
    if [[ "${NOKEY}" != "TRUE" ]] && [[ "${DISABLESSHCHECK}" != "TRUE" ]]; then
      notice "Checking SSH Configuration..."
      ssh_check
    else
      warning "This project is not configured to use SSH keys, no check needed."
    fi
    quiet_exit
  fi
}

# Check that dependencies exist
function check_dependencies() {
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
        cp "${stir_path}"/deploy.sh "${WORKPATH}/${APP}/${CONFIGDIR}/"
        APPRC="${WORKPATH}/${APP}/${CONFIGDIR}/stir.sh"
      else
        # If using root directory for .stir.sh
        cp "${stir_path}"/deploy.sh "${WORKPATH}/${APP}/.stir.sh"
        APPRC="${WORKPATH}/${APP}/.stir.sh"
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

  # If we're missing stuff that will be needed for --prepare, bail
  if [[ -n "${PREPARE}" ]]; then
    if [[ -n "${PREPARE_CONFIG}" ]] && [[ ! -f "${PREPARE_CONFIG}" ]]; then
      error "Can't read ${PREPARE_CONFIG}, exiting."
    fi
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
    [[ -n "${STAGING}" ]] && echo "Staging branch: ${STAGING}"
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
    [[ -n "${IN_EMAIL}" ]] && echo "Send email: ${IN_EMAIL}"
    [[ -n "${IN_INCLUDE_REPORT}" ]] && echo "Include report: ${IN_INCLUDE_REPORT}"
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
  quiet_exit
}
