#!/usr/bin/env bash
#
# utilities.sh
#
###############################################################################
# Handles various setup, logging, and option flags
###############################################################################

# Initialize variables
var=(integer_check json_key json_num cleaned_date cleaned_path wp_cmd \
  composer_cmd cmd_string)
init_loop

# Open a session, ask for user confirmation before beginning
function go() {
  if [[ "${QUIET}" != "1" ]]; then
    tput cnorm;
  fi

  # Get some project data for the logs; we only want to get server monitor 
  # info if we're not running a monitor test since we already loaded the 
  # password file contents into a variable
  if [[ "${TEST_MONITOR}" != "1" ]]; then
    server_monitor
  fi
  scan_check
  check_backup

  console "stir ${VERSION}"

  # Are we skipping git functions?
  if [[ "${SKIP_GIT}" == "1" ]]; then 
    if [[ "${DIGEST}" != "1" ]]; then
      error "Skipping git functionality is only allowed when using --digest"
    fi
  fi

  # Build only
  if [[ "${BUILD}" == "1" ]]; then
    build_check; quiet_exit
  fi  

  if [[ "${INCOGNITO}" != "TRUE" ]]; then
    console "Current working path is ${APP_PATH}"
  fi

  # Generate stats
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
  if [[ "${DO_NOT_DEPLOY}" == "TRUE" ]]; then
    warning "This project is currently locked."; quiet_exit
  fi

  # Is the user root?
  if [[ "${ALLOW_ROOT}" != "TRUE" ]] && [[ "${EUID}" -eq "0" ]]; then
    warning "Can't continue as root."; quiet_exit
  fi

  # Disallow server check?
  if [[ "${NOCHECK}" == "1" ]]; then
    CHECK_SERVER="FALSE";
    CHECK_ACTIVE="FALSE"
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
  if [[ "${REQUIRE_APPROVAL}" == "TRUE" ]] && [[ -f "${WORK_PATH}/${APP}/.queued" ]] && [[ -f "${WORK_PATH}/${APP}/.approved" ]]; then 
    notice "Processing outstanding approval..."
  fi

  if [[ "${NEWS_URL}" == "FALSE" ]]; then
    var=(NEWS_URL)
    init_loop
  fi
}

# Check that a variable is an integer
function is_integer() {
  declare arg1="${1}"; integer_check="0"
  if [[ ! "${arg1}" =~ ^[0-9]+$ ]]; then
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

  # Overwrite composer and wp commands if they are manually configured
  [[ ! -z "${WP_CLI_PATH}" ]] && wp_cmd=("${WP_CLI_PATH}")
  [[ ! -z "${COMPOSER_CLI_PATH}" ]] && composer_cmd=("${COMPOSER_CLI_PATH}")

  # If the user has SMTP configured, overwrite sendmail command with ssmtp
  check_smtp
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
# get_percent()
#   Get percentage
#
# Arguments:
#   [total]   Total quantity
#   [items]   Number from which to derive percent
#
# Example use:
#   get_percent 80 37
#   VARIABLE="$(get_percent ${var1} ${var2})"
############################################################################### 
function get_percent {
  declare arg1="${1}"
  declare arg2="${2}"
  if [[ -n "${arg1}" && -n "${arg2}" ]]; then
    awk "BEGIN { pc=100*${arg2}/${arg1}; i=int(pc); print (pc-i<0.5)?i:i+1 }" > /dev/null 2>&1
  fi
}

###############################################################################
# clean_path()
#   Strip extra forward slashes in URL or path directory values
#
# Arguments:
#   [path]         Input path or URL   
#
# Returns:
#   ${clean_path}  The post-precessed URL
#
# Example use:
#   clean_path path
############################################################################### 
function clean_path() {
  if [[ -n "${1}" ]]; then
    declare arg1="${1}"
    cleaned_path="$(echo ${arg1} | tr -s /)"
    # "${2}"=$(sed -i "s^//^/^g" "${1}")
    cleaned_path="$(echo ${cleaned_path} | sed -e 's#:/#://#g')"
  fi 
}

###############################################################################
# clean_date()
#   Format string containing default date format to be more readable 
#
# Arguments:
#   [date]        Date string  
#
# Example use:
#   clean_date 2021-10-29
############################################################################### 
function clean_date() {
  if [[ -n "${1}" ]]; then
    cleaned_date="$(date -d ${1} +'%B %d, %Y')"
  fi
}

###############################################################################
# set_fallback_values()
#   Set defaults for things liks SSH ports if missing
###############################################################################
function set_fallback_values() {
  [[ -z "${SCP_PORT}" ]] && SCP_PORT="22"
  [[ -z "${SCP_DEPLOY_PORT}" ]] && SCP_DEPLOY_PORT="22"
}

# User tests
function user_tests() {
  if [[ "${SHOW_SETTINGS}" == "1" ]]; then
    show_settings; quiet_exit
  fi

  # Slack test
  if [[ "${TEST_SLACK}" == "1" ]]; then
    slack_test; quiet_exit
  fi

  # Webhook POST test
  if [[ "${TEST_WEBHOOK}" == "1" ]]; then
    TEST_WEBHOOK; quiet_exit
  fi

  # Email test
  if [[ "${TEST_EMAIL}" == "1" ]]; then
    email_test; quiet_exit
  fi

  # Test analytics authentication
  if [[ "${TEST_ANALYTICS}" == "1" ]]; then
    ga_test; quiet_exit
  fi

  if [[ "${TEST_GA4}" == "1" ]]; then
    ga4_test; quiet_exit
  fi

  # Test server monitoring
  if [[ "${TEST_MONITOR}" == "1" ]]; then
    server_monitor_test; quiet_exit
  fi

  # Test Bugsnag integration
  if [[ "${TEST_BUGSNAG}" == "1" ]]; then
    test_bugsnag; quiet_exit
  fi

  # Test Mautic integration
  if [[ "${TEST_MAUTIC}" == "1" ]]; then
    mtc_test; quiet_exit
  fi

  # Test Dropbox backup authentication
  if [[ "${CHECK_BACKUP}" == "1" ]]; then
    check_backup; quiet_exit
  fi

  # Test SSH key authentication using the --ssh-check flag
  if [[ "${TEST_SSH}" == "1" ]]; then
    if [[ "${NO_KEY}" != "TRUE" ]] && [[ "${DISABLE_SSH_CHECK}" != "TRUE" ]]; then
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
    if [[ -w "${WORK_PATH}/${APP}" ]]; then
      empty_line; info "Project configuration not found, creating."; sleep 2
      # If configuration directory is defined
      if [[ -n "${CONFIG_DIR}" ]]; then
        if [[ ! -d "${WORK_PATH}/${APP}/${CONFIG_DIR}" ]]; then
          mkdir "${WORK_PATH}/${APP}/${CONFIG_DIR}"
        fi
        cp "${stir_path}"/stir-project.sh "${WORK_PATH}/${APP}/${CONFIG_DIR}/.stir.sh"
        APPRC="${WORK_PATH}/${APP}/${CONFIG_DIR}/stir.sh"
      else
        # If using root directory for .stir.sh
        cp "${stir_path}"/stir-project.sh "${WORK_PATH}/${APP}/.stir.sh"
        APPRC="${WORK_PATH}/${APP}/.stir.sh"
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
  if [[ "${EMAIL_ERROR}" == "TRUE" ]] || [[ "${EMAIL_SUCCESS}" == "TRUE" ]] || [[ "${EMAIL_QUIT}" == "TRUE" ]] || [[ "${NOTIFYCLIENT}" == "TRUE" ]]; then
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
  [[ -n "${WORK_PATH}" ]] && echo "Root project storage: ${WORK_PATH}"
  [[ -n "${REPO_HOST}" ]] && echo "REPO_HOST: ${REPO_HOST}"
  [[ -n "${CHECK_SERVER}" ]] && echo "Server checking: ${CHECK_SERVER}"
  [[ -n "${ALLOW_ROOT}" ]] && echo "Allow superuser: ${ALLOW_ROOT}"
  [[ -n "${CHECK_ACTIVE}" ]] && echo "Check file activity: ${CHECK_ACTIVE}"  
  [[ -n "${CHECK_TIME}" ]] && echo "Active time limit: ${CHECK_TIME} minutes"
  # Project
  notice "Project Information"
  echo "-------------------"
  [[ -n "${PROJECT_NAME}" ]] && echo "Name: ${PROJECT_NAME}"
  [[ -n "${PROJECT_CLIENT}" ]] && echo "Client: ${PROJECT_CLIENT}"
  [[ -n "${DEV_URL}" ]] && echo "Staging URL: ${DEV_URL}"
  [[ -n "${PROD_URL}" ]] && echo "Production URL: ${PROD_URL}"
  # Git
  if [[ -n "${REPO}" ]] || [[ -n "${MASTER}" ]] || [[ -n "${PRODUCTION}" ]] || [[ -n "${AUTOMERGE}" ]] || [[ -n "${STASH}" ]] || [[ -n "${CHECK_BRANCH}" ]]; then
    notice "Git Configuration"
    echo "-----------------"
    [[ -n "${REPO}" ]] && echo "Repo URL: ${REPO_HOST}/${REPO}"
    [[ -n "${REPO}" ]] && echo "Local repo path: ${APP_PATH}"
    [[ -n "${MASTER}" ]] && echo "Master branch: ${MASTER}"
    [[ -n "${STAGING}" ]] && echo "Staging branch: ${STAGING}"
    [[ -n "${PRODUCTION}" ]] && echo "Production branch: ${PRODUCTION}"
    [[ -n "${AUTOMERGE}" ]] && echo "Auto merge: ${AUTOMERGE}"
    [[ -n "${STASH}" ]] && echo "File Stashing: ${STASH}"
    [[ -n "${CHECK_BRANCH}" ]] && echo "Force branch checking: ${CHECK_BRANCH}" 
  fi
  # Wordpress
  if [[ -n "${WP_ROOT}" ]] || [[ -n "${WP_APP}" ]] || [[ -n "${WP_SYSTEM}" ]]; then
    notice "Wordpress Setup"
    echo "---------------"
    [[ -n "${WP_ROOT}" ]] && echo "Wordpress root: ${WP_ROOT}"
    [[ -n "${WP_APP}" ]] && echo "Wordpress application: ${WP_APP}"
    [[ -n "${WP_SYSTEM}" ]] && echo "Wordpress system: ${WP_SYSTEM}"
  fi
  # Deployment
  if [[ -n "${DEPLOY}" ]] || [[ -n "${DO_NOT_DEPLOY}" ]]; then
    notice "Deployment Configuration"
    echo "------------------------"
    [[ -n "${DEPLOY}" ]] && echo "Deploy command: ${DEPLOY}"
    [[ -n "${DO_NOT_DEPLOY}" ]] && echo "Disallow deployment: ${DO_NOT_DEPLOY}"
  fi
  # Notifications
  if [[ -n "${TASK}" ]] || [[ -n "${TASK_USER}" ]] || [[ -n "${ADD_TIME}" ]] || [[ -n "${POST_TO_SLACK}" ]] || [[ -n "${SLACK_ERROR}" ]] || [[ -n "${PROFILE_ID}" ]] || [[ -n "${POST_URL}" ]]; then
    notice "Notifications"
    echo "-------------"
    [[ -n "${TASK}" ]] && echo "Task #: ${TASK}"
    [[ -n "${TASK_USER}" ]] && echo "Task user: ${TASK_USER}"
    [[ -n "${ADD_TIME}" ]] && echo "Task time: ${ADD_TIME}"
    [[ -n "${POST_TO_SLACK}" ]] && echo "Post to Slack: ${POST_TO_SLACK}"
    [[ -n "${SLACK_ERROR}" ]] && echo "Post errors to Slack: ${SLACK_ERROR}"
    [[ -n "${POST_URL}" ]] && echo "Webhook URL: ${POST_URL}"
    [[ -n "${PROFILE_ID}" ]] && echo "Google Analytics ID: ${PROFILE_ID}"
  fi
  # Logging
  if [[ -n "${REMOTE_LOG}" ]] || [[ -n "${REMOTE_URL}" ]] || [[ -n "${EXPIRE_LOGS}" ]] || [[ -n "${POST_TO_LOCAL_HOST}" ]] || [[ -n "${LOCAL_HOST_PATH}" ]] || [[ -n "${SCP_POST}" ]] || [[ -n "${SCP_USER}" ]] || [[ -n "${SCP_HOST}" ]] || [[ -n "${SCP_HOST_PATH}" ]] || [[ -n "${SCP_PASS}" ]] || [[ -n "${REMOTE_TEMPLATE}" ]] || [[ -n "${REMOTE_TEMPLATE}" ]]; then
    notice "Logging"
    echo "-------"
    [[ -n "${TO}" ]] && echo "Send to: ${TO}"
    [[ -n "${HTML_TEMPLATE}" ]] && echo "Email template: ${HTML_TEMPLATE}"
    [[ -n "${CLIENT_LOGO}" ]] && echo "Logo: ${CLIENT_LOGO}"
    [[ -n "${COVER}" ]] && echo "Cover image: ${COVER}"
    [[ -n "${INCOGNITO}" ]] && echo "Logo: ${INCOGNITO}"
    [[ -n "${REMOTE_LOG}" ]] && echo "Web logs: ${REMOTE_LOG}"
    [[ -n "${REMOTE_URL}" ]] && echo "Address: ${REMOTE_URL}"
    [[ -n "${EXPIRE_LOGS}" ]] && echo "Log expiration: ${EXPIRE_LOGS} days"
    [[ -n "${REMOTE_TEMPLATE}" ]] && echo "Log template: ${REMOTE_TEMPLATE}"
    [[ -n "${SCP_POST}" ]] && echo "Post with SCP/SSH: ${SCP_POST}"
    [[ -n "${SCP_USER}" ]] && echo "SCP user: ${SCP_USER}"
    [[ -n "${SCP_HOST}" ]] && echo "Remote log host: ${SCP_HOST}"
    [[ -n "${SCP_HOST_PATH}" ]] && echo "Remote log path: ${SCP_HOST_PATH}"
    [[ -n "${POST_TO_LOCAL_HOST}" ]] && echo "Save logs locally: ${POST_TO_LOCAL_HOST}"
    [[ -n "${LOCAL_HOST_PATH}" ]] && echo "Path to local logs: ${}LOCAL_HOST_PATH"
  fi
  # Weekly Digests
  if [[ -n "${DIGEST_EMAIL}" ]]; then
    notice "Weekly Digests"
    echo "--------------"
    [[ -n "${DIGEST_EMAIL}" ]] && echo "Send to: ${DIGEST_EMAIL}"
  fi
  # Monthly Reporting
  if [[ -n "${CLIENT_CONTACT}" ]] || [[ -n "${INCLUDE_HOSTING}" ]]; then
    notice "Monthly Reporting"
    echo "-----------------"
    [[ -n "${CLIENT_CONTACT}" ]] && echo "Client contact: ${CLIENT_CONTACT}"
    [[ -n "${INCLUDE_HOSTING}" ]] && echo "Hosting notes: ${INCLUDE_HOSTING}"
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
  if [[ -n "${CLIENT_ID}" ]] || [[ -n "${CLIENT_SECRET}" ]] || [[ -n "${REDIRECT_URI}" ]] || [[ -n "${AUTHORIZATION_CODE}" ]] || [[ -n "${ACCESS_TOKEN}" ]] || [[ -n "${REFRESH_TOKEN}" ]] || [[ -n "${PROFILE_ID}" ]]; then
    notice "Google Analytics"
    echo "----------------"
    [[ -n "${CLIENT_ID}" ]] && echo "Client ID: ${CLIENT_ID}"
    [[ -n "${CLIENT_SECRET}" ]] && echo "Client secret: ${CLIENT_SECRET}"
    [[ -n "${REDIRECT_URI}" ]] && echo "Redirect URI: ${REDIRECT_URI}"
    [[ -n "${AUTHORIZATION_CODE}" ]] && echo "Authorization code: ${AUTHORIZATION_CODE}"
    [[ -n "${ACCESS_TOKEN}" ]] && echo "Access token: ${ACCESS_TOKEN}"
    [[ -n "${REFRESH_TOKEN}" ]] && echo "Refresh token: ${REFRESH_TOKEN}"
    [[ -n "${PROFILE_ID}" ]] && echo "Profile ID: ${PROFILE_ID}"
  fi
  # Server monitoring
  if [[ -n "${MONITOR_URL}" ]] || [[ -n "${MONITOR_USER}" ]] || [[ -n "${SERVER_ID}" ]]; then
    notice "Server Monitoring"
    echo "-----------------"
    [[ -n "${MONITOR_URL}" ]] && echo "Monitor URL: ${MONITOR_URL}"
    [[ -n "${MONITOR_USER}" ]] && echo "User: ${MONITOR_USER}"
    [[ -n "${SERVER_ID}" ]] && echo "Server ID: ${SERVER_ID}"
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
