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
go() {
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
    if [[ "${DIGEST}" != "1" || "${SWITCHES}" == *"test"*  ]]; then
      error "Skipping git functionality is only allowed when using --digest or test switches"
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

###############################################################################
# set_fallback_values()
#   Set defaults for things liks SSH ports if missing
###############################################################################
set_fallback_values() {
  [[ -z "${SCP_PORT}" ]] && SCP_PORT="22"
  [[ -z "${SCP_DEPLOY_PORT}" ]] && SCP_DEPLOY_PORT="22"
}

show_settings() {
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
