#!/usr/bin/env bash
#
# settings.sh
#
###############################################################################
# Global, user, and project configuration and settings
###############################################################################

# Initialize variables
var=(value remote_origin config_file)
init_loop

configure_project() {
  # 
  empty_line
  config_file="${APP_RC}"

  # REPO_HOST
  remote_origin="$(git ls-remote --get-url)"
  REPO_HOST=$(echo ${remote_origin%/*})
  arg="${REPO_HOST}"; read -rp "Repo root URL (including https://):" -e -i "${arg}" value; set_value "${value}"

  # Repo name
  REPO="$(basename -s .git `git config --get remote.origin.url`)"
  arg="${REPO}"; read -rp "Repo name:" -e -i "${arg}" value; set_value "${value}"

  # Branch name
  MASTER="$(git rev-parse --abbrev-ref HEAD)"
  arg="${MASTER}"; read -rp "Master branch name:" -e -i "${arg}" value; set_value "${value}"

  # Project name
  if [[ -z "${PROJECT_NAME}" ]]; then
    PROJECT_NAME="$(basename `git rev-parse --show-toplevel`)"
  fi
  arg="${PROJECT_NAME}"; read -rp "Project name:" -e -i "${arg} " value; set_value "${value}"
  #arg="${PROJECT_CLIENT}"; read -rp "Client name:" -e -i "${arg} " value; set_value "${value}"

  #arg="${DEV_URL}"; read -rp "Staging URL (including https://)" -e -i "${arg}" value; set_value "${value}"
  #arg="${PROD_URL}"; read -rp "Production URL (including https://)" -e -i "${arg}" value; set_value "${value}"
}

configure_user() {
  empty_line
  config_file="$HOME/.stirrc"
  arg="CLEAR_SCREEN"
  if yesno --default yes "Clear screen on startup? [Y/n] "; then
    set_value TRUE
  else
    unset_value
  fi

  arg="VERBOSE"
  if yesno --default no "Always show verbose output on console? [y/N] "; then
    set_value TRUE
  else
    unset_value
  fi  

  arg="GIT_STATS"
  if yesno --default yes "Display project statistics after every deployment? [Y/n] "; then
    set_value TRUE
  else
    unset_value
  fi
  [[ "${VERBOSE}" == "TRUE" ]] && VERBOSE="1"; empty_line
}

configure_global() {
  trace "This is an empty function"
}

set_value() {
  value="$1"
  sed -i -e "s^{{${arg}}}^${value}^g" \
    -e "s^# ${arg}^${arg}^g" "${config_file}"      
}

unset_value() {
  sed -i -e "s^{{${arg}}}^FALSE^g" "${config_file}"      
}

clear_user() {
settings=(CLEAR_SCREEN VERBOSE GIT_STATS)
empty_line
for arg in "${settings[@]}" ; do
  unset_value
done
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
  if [[ -n "${REPO}" ]] || [[ -n "${MASTER}" ]] || [[ -n "${PRODUCTION}" ]] || [[ -n "${AUTO_MERGE}" ]] || [[ -n "${STASH}" ]] || [[ -n "${CHECK_BRANCH}" ]]; then
    notice "Git Configuration"
    echo "-----------------"
    [[ -n "${REPO}" ]] && echo "Repo URL: ${REPO_HOST}/${REPO}"
    [[ -n "${REPO}" ]] && echo "Local repo path: ${APP_PATH}"
    [[ -n "${MASTER}" ]] && echo "Master branch: ${MASTER}"
    [[ -n "${STAGING}" ]] && echo "Staging branch: ${STAGING}"
    [[ -n "${PRODUCTION}" ]] && echo "Production branch: ${PRODUCTION}"
    [[ -n "${AUTO_MERGE}" ]] && echo "Auto merge: ${AUTO_MERGE}"
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
  fi
  # Logging
  if [[ -n "${REMOTE_LOG}" ]] || [[ -n "${REMOTE_URL}" ]] || [[ -n "${EXPIRE_LOGS}" ]] || [[ -n "${POST_TO_LOCAL_HOST}" ]] || [[ -n "${LOCAL_HOST_PATH}" ]] || [[ -n "${SCP_POST}" ]] || [[ -n "${SCP_USER}" ]] || [[ -n "${SCP_HOST}" ]] || [[ -n "${SCP_HOST_PATH}" ]] || [[ -n "${SCP_PASS}" ]]; then
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
    [[ -n "${IN_TOKEN}" ]] && echo "Token: ****"
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
    [[ -n "${CLIENT_ID}" ]] && echo "Client ID: ****"
    [[ -n "${CLIENT_SECRET}" ]] && echo "Client secret: ****"
    [[ -n "${REFRESH_TOKEN}" ]] && echo "Refresh token: ****"
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
    [[ -n "${DB_API_TOKEN}" ]] && echo "Token: ****"
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
