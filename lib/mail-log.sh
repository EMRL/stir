#!/usr/bin/env bash
#
# mail-log.sh
#
###############################################################################
# Mail handling
###############################################################################

function mail_log() {
  # Only send email if a commit has been made, an approval is required, or there has been an error
  if [[ -n "${COMMITHASH}" ]] || [[ "${message_state}" == "ERROR" ]] || [[ "${message_state}" == "APPROVAL NEEDED" ]] || [[ "${AUTOMATE}" == "1" ]]; then

    if [[ ! -x "$(command -v ${sendmail_cmd})" ]]; then
      quiet_exit
    fi

    # If using --current, use the REPO value instead of the APP (current directory)
    if [[ "${CURRENT}" == "1" ]]; then
      APP="${REPO}"
    fi

    if [[ "${EMAIL_HTML}" == "TRUE" ]]; then
      # Send the email
      (
      echo "Sender: ${FROM}"
      echo "From: ${FROM} <${FROM}>"
      echo "Reply-To: ${FROM} <${FROM}>"
      echo "To: ${TO}"
      echo "Subject: [${message_state}] ${SUBJECT} - ${APP}"              
      echo "Content-Type: text/html"
      echo
      echo "${htmlSendmail}";
      ) | "${sendmail_cmd}" -t
    else
      # Compile and send text format email
      textSendmail=$(<"${log_file}")
      (
      echo "Sender: ${FROM}"
      echo "From: ${FROM} <${FROM}>"
      echo "Reply-To: ${FROM} <${FROM}>"
      echo "To: ${TO}"
      echo "Subject: [${message_state}] ${SUBJECT} - ${APP}"          
      echo "Content-Type: text/plain"
      echo
      echo "${textSendmail}";
      ) | "${sendmail_cmd}" -t
    fi
  fi

  # Is this a digest email?
  if [[ "${message_state}" == "DIGEST" ]]; then
    # Send the email
    (
    echo "Sender: ${FROM}"
    echo "From: EMRL <${FROM}>"
    echo "Reply-To: ${FROM} <${FROM}>"
    echo "To: ${DIGEST_EMAIL}"
    echo "Subject: ${PROJECT_NAME} updates for the week of ${WEEKOF}"               
    echo "Content-Type: text/html"
    echo
    echo "${digest_payload}";
    ) | "${sendmail_cmd}" -t
  fi
}

function email_test() {
  # If the user has SMTP configured, overwrite sendmail command with ssmtp
  check_smtp
  
  # Make sure mail transport exists and is configured 
  if [[ -z "${sendmail_cmd}" ]]; then
    error >&2 "Mail system misconfigured or not found.";
  else
    console "Testing email using ${sendmail_cmd}"
  fi

  # Confirm we have a recipient address
  if [[ -z "${TO}" ]]; then
    empty_line; warning "No recipient address found."
    quiet_exit
  else
    # Send HTML mail
    (
    echo "Sender: ${FROM}"
    echo "From: ${FROM} <${FROM}>"
    echo "Reply-To: ${FROM} <${FROM}>"
    echo "To: ${TO}"
    echo "Subject: [TESTING] ${SUBJECT} - ${APP}"
    echo "Content-Type: text/html"
    echo
    echo "This is a test HTML email from <a href=\"https://github.com/EMRL/stir/\">stir ${VERSION}</a>.<br />"
    echo "Current user is ${DEV}<br /><br />";
    echo
    echo "<strong>Project Information</strong><br />"
    [[ -n "${PROJECT_NAME}" ]] && echo "Name: ${PROJECT_NAME}<br />"
    [[ -n "${PROJECT_CLIENT}" ]] && echo "Client: ${PROJECT_CLIENT}<br />"
    [[ -n "${DEV_URL}" ]] && echo "Staging URL: <a href=\"${DEV_URL}\">${DEV_URL}</a><br />"
    [[ -n "${PROD_URL}" ]] && echo "Production URL: <a href=\"${PROD_URL}\">${PROD_URL}</a><br />"
    echo "<br />"
    # Git
    if [[ -n "${REPO}" ]] || [[ -n "${MASTER}" ]] || [[ -n "${PRODUCTION}" ]] || [[ -n "${AUTOMERGE}" ]] || [[ -n "${STASH}" ]] || [[ -n "${CHECK_BRANCH}" ]]; then
      echo "<strong>Git Configuration</strong><br />"
      [[ -n "${REPO}" ]] && echo "Repo: <a href=\"${REPO_HOST}/${REPO}\">${REPO_HOST}/${REPO}</a><br />"
      [[ -n "${MASTER}" ]] && echo "Master branch: ${MASTER}<br />"
      [[ -n "${STAGING}" ]] && echo "Staging branch: ${STAGING}<br />"
      [[ -n "${PRODUCTION}" ]] && echo "Production branch: ${PRODUCTION}<br />"
      [[ -n "${AUTOMERGE}" ]] && echo "Auto merge: ${AUTOMERGE}<br />"
      [[ -n "${STASH}" ]] && echo "File Stashing: ${STASH}<br />"
      [[ -n "${CHECK_BRANCH}" ]] && echo "Force branch checking: ${CHECK_BRANCH}<br />"
      echo "<br />"
    fi
    # Wordpress
    if [[ -n "${WP_ROOT}" ]] || [[ -n "${WP_APP}" ]] || [[ -n "${WP_SYSTEM}" ]]; then
      echo "<strong>Wordpress Setup</strong><br />"
      [[ -n "${WP_ROOT}" ]] && echo "Wordpress root: ${WP_ROOT}<br />"
      [[ -n "${WP_APP}" ]] && echo "Wordpress application: ${WP_APP}<br />"
      [[ -n "${WP_SYSTEM}" ]] && echo "Wordpress system: ${WP_SYSTEM}<br />"
      echo "<br />"
    fi
    # Deployment
    if [[ -n "${DEPLOY}" ]] || [[ -n "${DO_NOT_DEPLOY}" ]]; then
      echo "<strong>Deployment Configuration</strong><br />"
      [[ -n "${DEPLOY}" ]] && echo "Deploy command: ${DEPLOY}<br />"
      [[ -n "${DO_NOT_DEPLOY}" ]] && echo "Disallow deployment: ${DO_NOT_DEPLOY}<br />"
      echo "<br />"
    fi
    # Notifications
    if [[ -n "${TASK}" ]] || [[ -n "${TASK_USER}" ]] || [[ -n "${ADD_TIME}" ]] || [[ -n "${POST_TO_SLACK}" ]] || [[ -n "${SLACK_ERROR}" ]] || [[ -n "${PROFILE_ID}" ]] || [[ -n "${POST_URL}" ]]; then
      echo "<strong>Notifications</strong><br />"
      [[ -n "${TASK}" ]] && echo "Task #: ${TASK}<br />"
      [[ -n "${TASK_USER}" ]] && echo "Task user: ${TASK_USER}<br />"
      [[ -n "${ADD_TIME}" ]] && echo "Task time: ${ADD_TIME}<br />"
      [[ -n "${POST_TO_SLACK}" ]] && echo "Post to Slack: ${POST_TO_SLACK}<br />"
      [[ -n "${SLACK_ERROR}" ]] && echo "Post errors to Slack: ${SLACK_ERROR}<br />"
      [[ -n "${POST_URL}" ]] && echo "Webhook URL: ${POST_URL}<br />"
      [[ -n "${PROFILE_ID}" ]] && echo "Google Analytics ID: ${PROFILE_ID}<br />"
      echo "<br />"
    fi
    # Logging
    if [[ -n "${REMOTE_LOG}" ]] || [[ -n "${REMOTE_URL}" ]] || [[ -n "${EXPIRE_LOGS}" ]] || [[ -n "${POST_TO_LOCAL_HOST}" ]] || [[ -n "${LOCAL_HOST_PATH}" ]] || [[ -n "${SCP_POST}" ]] || [[ -n "${SCP_USER}" ]] || [[ -n "${SCP_HOST}" ]] || [[ -n "${SCP_HOST_PATH}" ]] || [[ -n "${SCP_PASS}" ]] || [[ -n "${REMOTE_TEMPLATE}" ]] || [[ -n "${REMOTE_TEMPLATE}" ]]; then
      echo "<strong>Logging</strong><br />"
      [[ -n "${TO}" ]] && echo "Send to: ${TO}<br />"
      [[ -n "${HTML_TEMPLATE}" ]] && echo "Email template: ${HTML_TEMPLATE}<br />"
      [[ -n "${CLIENT_LOGO}" ]] && echo "Logo: ${CLIENT_LOGO}<br />"
      [[ -n "${COVER}" ]] && echo "Cover image: ${COVER}<br />"
      [[ -n "${INCOGNITO}" ]] && echo "Logo: ${INCOGNITO}<br />"
      [[ -n "${REMOTE_LOG}" ]] && echo "Web logs: ${REMOTE_LOG}<br />"
      [[ -n "${REMOTE_URL}" ]] && echo "Address: ${REMOTE_URL} <br />"
      [[ -n "${EXPIRE_LOGS}" ]] && echo "Log expiration: ${EXPIRE_LOGS} days <br />"
      [[ -n "${REMOTE_TEMPLATE}" ]] && echo "Log template: ${REMOTE_TEMPLATE}<br />"
      [[ -n "${SCP_POST}" ]] && echo "Post with SCP/SSH: ${SCP_POST}<br />"
      [[ -n "${SCP_USER}" ]] && echo "SCP user: ${SCP_USER}<br />"
      [[ -n "${SCP_HOST}" ]] && echo "Remote log host: ${SCP_HOST}<br />"
      [[ -n "${SCP_HOST_PATH}" ]] && echo "Remote log path: ${SCP_HOST_PATH}<br />"
      [[ -n "${POST_TO_LOCAL_HOST}" ]] && echo "Save logs locally: ${POST_TO_LOCAL_HOST}<br />"
      [[ -n "${LOCAL_HOST_PATH}" ]] && echo "Path to local logs: ${}LOCAL_HOST_PATH<br />"
      echo "<br />"
    fi
    # Weekly Digests
    if [[ -n "${DIGEST_EMAIL}" ]]; then
      echo "<strong>Weekly Digests</strong><br />"
      [[ -n "${DIGEST_EMAIL}" ]] && echo "Send to: ${DIGEST_EMAIL}<br />"
      echo "<br />"
    fi
    # Monthly Reporting
    if [[ -n "${CLIENT_CONTACT}" ]] || [[ -n "${INCLUDE_HOSTING}" ]]; then
      echo "<strong>Monthly Reporting</strong><br />"
      [[ -n "${CLIENT_CONTACT}" ]] && echo "Client contact: ${CLIENT_CONTACT}<br />"
      [[ -n "${INCLUDE_HOSTING}" ]] && echo "Hosting notes: ${INCLUDE_HOSTING}<br />"
      echo "<br />"
    fi
    # Invoice Ninja integration
    if [[ -n "${IN_HOST}" ]] || [[ -n "${IN_TOKEN}" ]] || [[ -n "${IN_CLIENT_ID}" ]] || [[ -n "${IN_PRODUCT}" ]] || [[ -n "${IN_ITEM_COST}" ]] || [[ -n "${IN_ITEM_QTY}" ]] || [[ -n "${IN_NOTES}" ]] || [[ -n "${IN_NOTES}" ]]; then
      echo "<strong>Invoice Ninja Integration</strong><br />"
      [[ -n "${IN_HOST}" ]] && echo "Host: ${IN_HOST}<br />"
      [[ -n "${IN_TOKEN}" ]] && echo "Token: ${IN_TOKEN}<br />"
      [[ -n "${IN_CLIENT_ID}" ]] && echo "Client ID: ${IN_CLIENT_ID}<br />"
      [[ -n "${IN_PRODUCT}" ]] && echo "Product: ${IN_PRODUCT}<br />"
      [[ -n "${IN_ITEM_COST}" ]] && echo "Item cost: ${IN_ITEM_COST}<br />"
      [[ -n "${IN_ITEM_QTY}" ]] && echo "Item quantity: ${IN_ITEM_QTY}<br />"
      [[ -n "${IN_NOTES}" ]] && echo "Notes: ${IN_NOTES}<br />"
      echo "<br />"
    fi
    # Google Analytics
    if [[ -n "${CLIENT_ID}" ]] || [[ -n "${CLIENT_SECRET}" ]] || [[ -n "${REDIRECT_URI}" ]] || [[ -n "${AUTHORIZATION_CODE}" ]] || [[ -n "${ACCESS_TOKEN}" ]] || [[ -n "${REFRESH_TOKEN}" ]] || [[ -n "${PROFILE_ID}" ]]; then
      echo "<strong>Google Analytics</strong><br />"
      [[ -n "${CLIENT_ID}" ]] && echo "Client ID: ${CLIENT_ID}<br />"
      [[ -n "${CLIENT_SECRET}" ]] && echo "Client secret: ${CLIENT_SECRET}<br />"
      [[ -n "${REDIRECT_URI}" ]] && echo "Redirect URI: ${REDIRECT_URI}<br />"
      [[ -n "${AUTHORIZATION_CODE}" ]] && echo "Authorization code: ${AUTHORIZATION_CODE}<br />"
      [[ -n "${ACCESS_TOKEN}" ]] && echo "Access token: ${ACCESS_TOKEN}<br />"
      [[ -n "${REFRESH_TOKEN}" ]] && echo "Refresh token: ${REFRESH_TOKEN}<br />"
      [[ -n "${PROFILE_ID}" ]] && echo "Profile ID: ${PROFILE_ID}<br />"
      echo "<br />"
    fi
    # Server monitoring
    if [[ -n "${MONITOR_URL}" ]] || [[ -n "${MONITOR_USER}" ]] || [[ -n "${SERVER_ID}" ]]; then
      echo "<strong>Server Monitoring</strong><br />"
      [[ -n "${MONITOR_URL}" ]] && echo "Monitor URL: ${MONITOR_URL}<br />"
      [[ -n "${MONITOR_USER}" ]] && echo "User: ${MONITOR_USER}<br />"
      [[ -n "${SERVER_ID}" ]] && echo "Server ID: ${SERVER_ID}<br />"
      echo "<br />"
    fi
    # Dropbox integration
    if [[ -n "${DB_API_TOKEN}" ]] || [[ -n "${DB_BACKUP_PATH}" ]]; then
      echo "<strong>Dropbox Integration</strong><br />"
      [[ -n "${DB_API_TOKEN}" ]] && echo "Token: ${DB_API_TOKEN}<br />"
      [[ -n "${DB_BACKUP_PATH}" ]] && echo "Backup path: ${DB_BACKUP_PATH}<br />"
      echo "<br />"
    fi
    # Malware scanning
    if [[ -n "${NIKTO}" ]] || [[ -n "${NIKTO_CONFIG}" ]] || [[ -n "${NIKTO_PROXY}" ]]; then
      echo "<strong>Malware Scanning</strong><br />"
      [[ -n "${NIKTO}" ]] && echo "Scanner: ${NIKTO}<br />"
      [[ -n "${NIKTO_CONFIG}" ]] && echo "Configuration path: ${NIKTO_CONFIG}<br />"
      [[ -n "${NIKTO_PROXY}" ]] && echo "Proxy: ${NIKTO_PROXY}<br />"
      echo "<br />"
    fi
    ) | "${sendmail_cmd}" -t

    # Send text mail
    (
    echo "Sender: ${FROM}"
    echo "From: ${FROM} <${FROM}>"
    echo "Reply-To: ${FROM} <${FROM}>"
    echo "To: ${TO}"
    echo "Subject: [TESTING] ${SUBJECT} - ${APP}"
    echo "Content-Type: text/plain"
    echo
    echo "This is a test TEXT email from stir ${VERSION} (https://github.com/EMRL/stir/)"
    echo "Current user is ${DEV}";
    echo
    echo "Project Information"
    echo "-------------------"
    [[ -n "${PROJECT_NAME}" ]] && echo "Name: ${PROJECT_NAME}"
    [[ -n "${PROJECT_CLIENT}" ]] && echo "Client: ${PROJECT_CLIENT}"
    [[ -n "${DEV_URL}" ]] && echo "Staging URL: ${DEV_URL}"
    [[ -n "${PROD_URL}" ]] && echo "Production URL: ${PROD_URL}"
    echo 
    # Git
    if [[ -n "${REPO}" ]] || [[ -n "${MASTER}" ]] || [[ -n "${PRODUCTION}" ]] || [[ -n "${AUTOMERGE}" ]] || [[ -n "${STASH}" ]] || [[ -n "${CHECK_BRANCH}" ]]; then
      echo "Git Configuration"
      echo "-----------------"
      [[ -n "${REPO}" ]] && echo "Repo: ${REPO_HOST}/${REPO}"
      [[ -n "${MASTER}" ]] && echo "Master branch: ${MASTER}"
      [[ -n "${STAGING}" ]] && echo "Staging branch: ${STAGING}"
      [[ -n "${PRODUCTION}" ]] && echo "Production branch: ${PRODUCTION}"
      [[ -n "${AUTOMERGE}" ]] && echo "Auto merge: ${AUTOMERGE}"
      [[ -n "${STASH}" ]] && echo "File Stashing: ${STASH}"
      [[ -n "${CHECK_BRANCH}" ]] && echo "Force branch checking: ${CHECK_BRANCH}"
      echo 
    fi
    # Wordpress
    if [[ -n "${WP_ROOT}" ]] || [[ -n "${WP_APP}" ]] || [[ -n "${WP_SYSTEM}" ]]; then
      echo "Wordpress Setup"
      echo "---------------"
      [[ -n "${WP_ROOT}" ]] && echo "Wordpress root: ${WP_ROOT}"
      [[ -n "${WP_APP}" ]] && echo "Wordpress application: ${WP_APP}"
      [[ -n "${WP_SYSTEM}" ]] && echo "Wordpress system: ${WP_SYSTEM}"
      echo
    fi
    # Deployment
    if [[ -n "${DEPLOY}" ]] || [[ -n "${DO_NOT_DEPLOY}" ]]; then
      echo "Deployment Configuration"
      echo "------------------------"
      [[ -n "${DEPLOY}" ]] && echo "Deploy command: ${DEPLOY}"
      [[ -n "${DO_NOT_DEPLOY}" ]] && echo "Disallow deployment: ${DO_NOT_DEPLOY}"
      echo
    fi
    # Notifications
    if [[ -n "${TASK}" ]] || [[ -n "${TASK_USER}" ]] || [[ -n "${ADD_TIME}" ]] || [[ -n "${POST_TO_SLACK}" ]] || [[ -n "${SLACK_ERROR}" ]] || [[ -n "${PROFILE_ID}" ]] || [[ -n "${POST_URL}" ]]; then
      echo "Notifications"
      echo "-------------"
      [[ -n "${TASK}" ]] && echo "Task #: ${TASK}"
      [[ -n "${TASK_USER}" ]] && echo "Task user: ${TASK_USER}"
      [[ -n "${ADD_TIME}" ]] && echo "Task time: ${ADD_TIME}"
      [[ -n "${POST_TO_SLACK}" ]] && echo "Post to Slack: ${POST_TO_SLACK}"
      [[ -n "${SLACK_ERROR}" ]] && echo "Post errors to Slack: ${SLACK_ERROR}"
      [[ -n "${POST_URL}" ]] && echo "Webhook URL: ${POST_URL}"
      [[ -n "${PROFILE_ID}" ]] && echo "Google Analytics ID: ${PROFILE_ID}"
      echo
    fi
    # Logging
    if [[ -n "${REMOTE_LOG}" ]] || [[ -n "${REMOTE_URL}" ]] || [[ -n "${EXPIRE_LOGS}" ]] || [[ -n "${POST_TO_LOCAL_HOST}" ]] || [[ -n "${LOCAL_HOST_PATH}" ]] || [[ -n "${SCP_POST}" ]] || [[ -n "${SCP_USER}" ]] || [[ -n "${SCP_HOST}" ]] || [[ -n "${SCP_HOST_PATH}" ]] || [[ -n "${SCP_PASS}" ]] || [[ -n "${REMOTE_TEMPLATE}" ]] || [[ -n "${REMOTE_TEMPLATE}" ]]; then
      echo "Logging"
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
      echo
    fi
    # Weekly Digests
    if [[ -n "${DIGEST_EMAIL}" ]]; then
      echo "Weekly Digests"
      echo "--------------"
      [[ -n "${DIGEST_EMAIL}" ]] && echo "Send to: ${DIGEST_EMAIL}"
      echo
    fi
    # Monthly Reporting
    if [[ -n "${CLIENT_CONTACT}" ]] || [[ -n "${INCLUDE_HOSTING}" ]]; then
      echo "Monthly Reporting"
      echo "-----------------"
      [[ -n "${CLIENT_CONTACT}" ]] && echo "Client contact: ${CLIENT_CONTACT}"
      [[ -n "${INCLUDE_HOSTING}" ]] && echo "Hosting notes: ${INCLUDE_HOSTING}"
      echo
    fi
    # Invoice Ninja integration
    if [[ -n "${IN_HOST}" ]] || [[ -n "${IN_TOKEN}" ]] || [[ -n "${IN_CLIENT_ID}" ]] || [[ -n "${IN_PRODUCT}" ]] || [[ -n "${IN_ITEM_COST}" ]] || [[ -n "${IN_ITEM_QTY}" ]] || [[ -n "${IN_NOTES}" ]] || [[ -n "${IN_NOTES}" ]]; then
      echo "Invoice Ninja Integration"
      [[ -n "${IN_HOST}" ]] && echo "Host: ${IN_HOST}"
      [[ -n "${IN_TOKEN}" ]] && echo "Token: ${IN_TOKEN}"
      [[ -n "${IN_CLIENT_ID}" ]] && echo "Client ID: ${IN_CLIENT_ID}"
      [[ -n "${IN_PRODUCT}" ]] && echo "Product: ${IN_PRODUCT}"
      [[ -n "${IN_ITEM_COST}" ]] && echo "Item cost: ${IN_ITEM_COST}"
      [[ -n "${IN_ITEM_QTY}" ]] && echo "Item quantity: ${IN_ITEM_QTY}"
      [[ -n "${IN_NOTES}" ]] && echo "Notes: ${IN_NOTES}"
      echo
    fi
    # Google Analytics
    if [[ -n "${CLIENT_ID}" ]] || [[ -n "${CLIENT_SECRET}" ]] || [[ -n "${REDIRECT_URI}" ]] || [[ -n "${AUTHORIZATION_CODE}" ]] || [[ -n "${ACCESS_TOKEN}" ]] || [[ -n "${REFRESH_TOKEN}" ]] || [[ -n "${PROFILE_ID}" ]]; then
      echo "Google Analytics"
      echo "----------------"
      [[ -n "${CLIENT_ID}" ]] && echo "Client ID: ${CLIENT_ID}"
      [[ -n "${CLIENT_SECRET}" ]] && echo "Client secret: ${CLIENT_SECRET}"
      [[ -n "${REDIRECT_URI}" ]] && echo "Redirect URI: ${REDIRECT_URI}"
      [[ -n "${AUTHORIZATION_CODE}" ]] && echo "Authorization code: ${AUTHORIZATION_CODE}"
      [[ -n "${ACCESS_TOKEN}" ]] && echo "Access token: ${ACCESS_TOKEN}"
      [[ -n "${REFRESH_TOKEN}" ]] && echo "Refresh token: ${REFRESH_TOKEN}"
      [[ -n "${PROFILE_ID}" ]] && echo "Profile ID: ${PROFILE_ID}"
      echo
    fi
    # Server monitoring
    if [[ -n "${MONITOR_URL}" ]] || [[ -n "${MONITOR_USER}" ]] || [[ -n "${SERVER_ID}" ]]; then
      echo "Server Monitoring"
      echo "-----------------"
      [[ -n "${MONITOR_URL}" ]] && echo "Monitor URL: ${MONITOR_URL}"
      [[ -n "${MONITOR_USER}" ]] && echo "User: ${MONITOR_USER}"
      [[ -n "${SERVER_ID}" ]] && echo "Server ID: ${SERVER_ID}"
      echo
    fi
    # Dropbox integration
    if [[ -n "${DB_API_TOKEN}" ]] || [[ -n "${DB_BACKUP_PATH}" ]]; then
      echo "Dropbox Integration"
      echo "-------------------"
      [[ -n "${DB_API_TOKEN}" ]] && echo "Token: ${DB_API_TOKEN}"
      [[ -n "${DB_BACKUP_PATH}" ]] && echo "Backup path: ${DB_BACKUP_PATH}"
      echo
    fi
    # Malware scanning
    if [[ -n "${NIKTO}" ]] || [[ -n "${NIKTO_CONFIG}" ]] || [[ -n "${NIKTO_PROXY}" ]]; then
      echo "Malware Scanning"
      echo "----------------"
      [[ -n "${NIKTO}" ]] && echo "Scanner: ${NIKTO}"
      [[ -n "${NIKTO_CONFIG}" ]] && echo "Configuration path: ${NIKTO_CONFIG}"
      [[ -n "${NIKTO_PROXY}" ]] && echo "Proxy: ${NIKTO_PROXY}"
      echo
    fi
    ) | "${sendmail_cmd}" -t
  fi

  # If an integration is setup, let's test it
  if [[ ! -z "${TASK}" ]]; then
    sleep 2
    if [[ "${POST_EMAIL_HEAD}${TASK}${POST_EMAIL_TAIL}" == ?*@?*.?* ]]; then
      console "Testing integration to ${integration_email}"
      (
      if [[ -z "${TASK_USER}" ]] || [[ -z "${ADD_TIME}" ]]; then
        echo "From: ${FROM}"
      else
        echo "From: ${TASK_USER}"
      fi
      echo "Reply-To: ${FROM} <${FROM}>"
      echo "To: ${POST_EMAIL_HEAD}${TASK}${POST_EMAIL_TAIL}"
      echo "Subject: [TESTING] ${SUBJECT} - ${APP}"
      echo "Content-Type: text/plain"
      echo
      echo "This is a test email integration from stir ${VERSION}"
      echo "(https://github.com/EMRL/stir/)"
      echo
      [[ -n "${PROJECT_NAME}" ]] && echo "Name: ${PROJECT_NAME}"
      [[ -n "${PROJECT_CLIENT}" ]] && echo "Client: ${PROJECT_CLIENT}"
      [[ -n "${DEV_URL}" ]] && echo "Staging URL: ${DEV_URL}"
      [[ -n "${PROD_URL}" ]] && echo "Production URL: ${PROD_URL}"
      ) | "${sendmail_cmd}" -t
      quiet_exit
    else
      console "Integration email address ${POST_EMAIL_HEAD}${TASK}${POST_EMAIL_TAIL} does not look valid"; quiet_exit
    fi
  fi
}
