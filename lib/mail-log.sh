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

    if [[ "${EMAILHTML}" == "TRUE" ]]; then
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
  if [[ -n "${DIGESTEMAIL}" ]] && [[ "${DIGEST}" == "1" ]] && [[ -n "${digestSendmail}" ]]; then
    # Send the email
    (
    echo "Sender: ${FROM}"
    echo "From: EMRL <${FROM}>"
    echo "Reply-To: ${FROM} <${FROM}>"
    echo "To: ${DIGESTEMAIL}"
    echo "Subject: ${PROJNAME} updates for the week of ${WEEKOF}"               
    echo "Content-Type: text/html"
    echo
    echo "${digestSendmail}";
    ) | "${sendmail_cmd}" -t
  fi
}

function email_test() {
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
    [[ -n "${PROJNAME}" ]] && echo "Name: ${PROJNAME}<br />"
    [[ -n "${PROJCLIENT}" ]] && echo "Client: ${PROJCLIENT}<br />"
    [[ -n "${DEVURL}" ]] && echo "Staging URL: <a href=\"${DEVURL}\">${DEVURL}</a><br />"
    [[ -n "${PRODURL}" ]] && echo "Production URL: <a href=\"${PRODURL}\">${PRODURL}</a><br />"
    echo "<br />"
    # Git
    if [[ -n "${REPO}" ]] || [[ -n "${MASTER}" ]] || [[ -n "${PRODUCTION}" ]] || [[ -n "${AUTOMERGE}" ]] || [[ -n "${STASH}" ]] || [[ -n "${CHECKBRANCH}" ]]; then
      echo "<strong>Git Configuration</strong><br />"
      [[ -n "${REPO}" ]] && echo "Repo: <a href=\"${REPOHOST}/${REPO}\">${REPOHOST}/${REPO}</a><br />"
      [[ -n "${MASTER}" ]] && echo "Master branch: ${MASTER}<br />"
      [[ -n "${STAGING}" ]] && echo "Staging branch: ${STAGING}<br />"
      [[ -n "${PRODUCTION}" ]] && echo "Production branch: ${PRODUCTION}<br />"
      [[ -n "${AUTOMERGE}" ]] && echo "Auto merge: ${AUTOMERGE}<br />"
      [[ -n "${STASH}" ]] && echo "File Stashing: ${STASH}<br />"
      [[ -n "${CHECKBRANCH}" ]] && echo "Force branch checking: ${CHECKBRANCH}<br />"
      echo "<br />"
    fi
    # Wordpress
    if [[ -n "${WPROOT}" ]] || [[ -n "${WPAPP}" ]] || [[ -n "${WPSYSTEM}" ]]; then
      echo "<strong>Wordpress Setup</strong><br />"
      [[ -n "${WPROOT}" ]] && echo "Wordpress root: ${WPROOT}<br />"
      [[ -n "${WPAPP}" ]] && echo "Wordpress application: ${WPAPP}<br />"
      [[ -n "${WPSYSTEM}" ]] && echo "Wordpress system: ${WPSYSTEM}<br />"
      echo "<br />"
    fi
    # Deployment
    if [[ -n "${DEPLOY}" ]] || [[ -n "${DONOTDEPLOY}" ]]; then
      echo "<strong>Deployment Configuration</strong><br />"
      [[ -n "${DEPLOY}" ]] && echo "Deploy command: ${DEPLOY}<br />"
      [[ -n "${DONOTDEPLOY}" ]] && echo "Disallow deployment: ${DONOTDEPLOY}<br />"
      echo "<br />"
    fi
    # Notifications
    if [[ -n "${TASK}" ]] || [[ -n "${TASKUSER}" ]] || [[ -n "${ADDTIME}" ]] || [[ -n "${POSTTOSLACK}" ]] || [[ -n "${SLACKERROR}" ]] || [[ -n "${PROFILEID}" ]] || [[ -n "${POSTURL}" ]]; then
      echo "<strong>Notifications</strong><br />"
      [[ -n "${TASK}" ]] && echo "Task #: ${TASK}<br />"
      [[ -n "${TASKUSER}" ]] && echo "Task user: ${TASKUSER}<br />"
      [[ -n "${ADDTIME}" ]] && echo "Task time: ${ADDTIME}<br />"
      [[ -n "${POSTTOSLACK}" ]] && echo "Post to Slack: ${POSTTOSLACK}<br />"
      [[ -n "${SLACKERROR}" ]] && echo "Post errors to Slack: ${SLACKERROR}<br />"
      [[ -n "${POSTURL}" ]] && echo "Webhook URL: ${POSTURL}<br />"
      [[ -n "${PROFILEID}" ]] && echo "Google Analytics ID: ${PROFILEID}<br />"
      echo "<br />"
    fi
    # Logging
    if [[ -n "${REMOTELOG}" ]] || [[ -n "${REMOTEURL}" ]] || [[ -n "${EXPIRELOGS}" ]] || [[ -n "${LOCALHOSTPOST}" ]] || [[ -n "${LOCALHOSTPATH}" ]] || [[ -n "${SCPPOST}" ]] || [[ -n "${SCPUSER}" ]] || [[ -n "${SCPHOST}" ]] || [[ -n "${SCPHOSTPATH}" ]] || [[ -n "${SCPPASS}" ]] || [[ -n "${REMOTETEMPLATE}" ]] || [[ -n "${REMOTETEMPLATE}" ]]; then
      echo "<strong>Logging</strong><br />"
      [[ -n "${TO}" ]] && echo "Send to: ${TO}<br />"
      [[ -n "${HTMLTEMPLATE}" ]] && echo "Email template: ${HTMLTEMPLATE}<br />"
      [[ -n "${CLIENTLOGO}" ]] && echo "Logo: ${CLIENTLOGO}<br />"
      [[ -n "${COVER}" ]] && echo "Cover image: ${COVER}<br />"
      [[ -n "${INCOGNITO}" ]] && echo "Logo: ${INCOGNITO}<br />"
      [[ -n "${REMOTELOG}" ]] && echo "Web logs: ${REMOTELOG}<br />"
      [[ -n "${REMOTEURL}" ]] && echo "Address: ${REMOTEURL} <br />"
      [[ -n "${EXPIRELOGS}" ]] && echo "Log expiration: ${EXPIRELOGS} days <br />"
      [[ -n "${REMOTETEMPLATE}" ]] && echo "Log template: ${REMOTETEMPLATE}<br />"
      [[ -n "${SCPPOST}" ]] && echo "Post with SCP/SSH: ${SCPPOST}<br />"
      [[ -n "${SCPUSER}" ]] && echo "SCP user: ${SCPUSER}<br />"
      [[ -n "${SCPHOST}" ]] && echo "Remote log host: ${SCPHOST}<br />"
      [[ -n "${SCPHOSTPATH}" ]] && echo "Remote log path: ${SCPHOSTPATH}<br />"
      [[ -n "${SCPHOSTPORT}" ]] && echo "Remote log path: ${SCPHOSTPORT}<br />"
      [[ -n "${LOCALHOSTPOST}" ]] && echo "Save logs locally: ${LOCALHOSTPOST}<br />"
      [[ -n "${LOCALHOSTPATH}" ]] && echo "Path to local logs: ${}LOCALHOSTPATH<br />"
      echo "<br />"
    fi
    # Weekly Digests
    if [[ -n "${DIGESTEMAIL}" ]]; then
      echo "<strong>Weekly Digests</strong><br />"
      [[ -n "${DIGESTEMAIL}" ]] && echo "Send to: ${DIGESTEMAIL}<br />"
      echo "<br />"
    fi
    # Monthly Reporting
    if [[ -n "${CLIENTCONTACT}" ]] || [[ -n "${INCLUDEHOSTING}" ]]; then
      echo "<strong>Monthly Reporting</strong><br />"
      [[ -n "${CLIENTCONTACT}" ]] && echo "Client contact: ${CLIENTCONTACT}<br />"
      [[ -n "${INCLUDEHOSTING}" ]] && echo "Hosting notes: ${INCLUDEHOSTING}<br />"
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
    if [[ -n "${CLIENTID}" ]] || [[ -n "${CLIENTSECRET}" ]] || [[ -n "${REDIRECTURI}" ]] || [[ -n "${AUTHORIZATIONCODE}" ]] || [[ -n "${ACCESSTOKEN}" ]] || [[ -n "${REFRESHTOKEN}" ]] || [[ -n "${PROFILEID}" ]]; then
      echo "<strong>Google Analytics</strong><br />"
      [[ -n "${CLIENTID}" ]] && echo "Client ID: ${CLIENTID}<br />"
      [[ -n "${CLIENTSECRET}" ]] && echo "Client secret: ${CLIENTSECRET}<br />"
      [[ -n "${REDIRECTURI}" ]] && echo "Redirect URI: ${REDIRECTURI}<br />"
      [[ -n "${AUTHORIZATIONCODE}" ]] && echo "Authorization code: ${AUTHORIZATIONCODE}<br />"
      [[ -n "${ACCESSTOKEN}" ]] && echo "Access token: ${ACCESSTOKEN}<br />"
      [[ -n "${REFRESHTOKEN}" ]] && echo "Refresh token: ${REFRESHTOKEN}<br />"
      [[ -n "${PROFILEID}" ]] && echo "Profile ID: ${PROFILEID}<br />"
      echo "<br />"
    fi
    # Server monitoring
    if [[ -n "${MONITORURL}" ]] || [[ -n "${MONITORUSER}" ]] || [[ -n "${SERVERID}" ]]; then
      echo "<strong>Server Monitoring</strong><br />"
      [[ -n "${MONITORURL}" ]] && echo "Monitor URL: ${MONITORURL}<br />"
      [[ -n "${MONITORUSER}" ]] && echo "User: ${MONITORUSER}<br />"
      [[ -n "${SERVERID}" ]] && echo "Server ID: ${SERVERID}<br />"
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
    [[ -n "${PROJNAME}" ]] && echo "Name: ${PROJNAME}"
    [[ -n "${PROJCLIENT}" ]] && echo "Client: ${PROJCLIENT}"
    [[ -n "${DEVURL}" ]] && echo "Staging URL: ${DEVURL}"
    [[ -n "${PRODURL}" ]] && echo "Production URL: ${PRODURL}"
    echo 
    # Git
    if [[ -n "${REPO}" ]] || [[ -n "${MASTER}" ]] || [[ -n "${PRODUCTION}" ]] || [[ -n "${AUTOMERGE}" ]] || [[ -n "${STASH}" ]] || [[ -n "${CHECKBRANCH}" ]]; then
      echo "Git Configuration"
      echo "-----------------"
      [[ -n "${REPO}" ]] && echo "Repo: ${REPOHOST}/${REPO}"
      [[ -n "${MASTER}" ]] && echo "Master branch: ${MASTER}"
      [[ -n "${STAGING}" ]] && echo "Staging branch: ${STAGING}"
      [[ -n "${PRODUCTION}" ]] && echo "Production branch: ${PRODUCTION}"
      [[ -n "${AUTOMERGE}" ]] && echo "Auto merge: ${AUTOMERGE}"
      [[ -n "${STASH}" ]] && echo "File Stashing: ${STASH}"
      [[ -n "${CHECKBRANCH}" ]] && echo "Force branch checking: ${CHECKBRANCH}"
      echo 
    fi
    # Wordpress
    if [[ -n "${WPROOT}" ]] || [[ -n "${WPAPP}" ]] || [[ -n "${WPSYSTEM}" ]]; then
      echo "Wordpress Setup"
      echo "---------------"
      [[ -n "${WPROOT}" ]] && echo "Wordpress root: ${WPROOT}"
      [[ -n "${WPAPP}" ]] && echo "Wordpress application: ${WPAPP}"
      [[ -n "${WPSYSTEM}" ]] && echo "Wordpress system: ${WPSYSTEM}"
      echo
    fi
    # Deployment
    if [[ -n "${DEPLOY}" ]] || [[ -n "${DONOTDEPLOY}" ]]; then
      echo "Deployment Configuration"
      echo "------------------------"
      [[ -n "${DEPLOY}" ]] && echo "Deploy command: ${DEPLOY}"
      [[ -n "${DONOTDEPLOY}" ]] && echo "Disallow deployment: ${DONOTDEPLOY}"
      echo
    fi
    # Notifications
    if [[ -n "${TASK}" ]] || [[ -n "${TASKUSER}" ]] || [[ -n "${ADDTIME}" ]] || [[ -n "${POSTTOSLACK}" ]] || [[ -n "${SLACKERROR}" ]] || [[ -n "${PROFILEID}" ]] || [[ -n "${POSTURL}" ]]; then
      echo "Notifications"
      echo "-------------"
      [[ -n "${TASK}" ]] && echo "Task #: ${TASK}"
      [[ -n "${TASKUSER}" ]] && echo "Task user: ${TASKUSER}"
      [[ -n "${ADDTIME}" ]] && echo "Task time: ${ADDTIME}"
      [[ -n "${POSTTOSLACK}" ]] && echo "Post to Slack: ${POSTTOSLACK}"
      [[ -n "${SLACKERROR}" ]] && echo "Post errors to Slack: ${SLACKERROR}"
      [[ -n "${POSTURL}" ]] && echo "Webhook URL: ${POSTURL}"
      [[ -n "${PROFILEID}" ]] && echo "Google Analytics ID: ${PROFILEID}"
      echo
    fi
    # Logging
    if [[ -n "${REMOTELOG}" ]] || [[ -n "${REMOTEURL}" ]] || [[ -n "${EXPIRELOGS}" ]] || [[ -n "${LOCALHOSTPOST}" ]] || [[ -n "${LOCALHOSTPATH}" ]] || [[ -n "${SCPPOST}" ]] || [[ -n "${SCPUSER}" ]] || [[ -n "${SCPHOST}" ]] || [[ -n "${SCPHOSTPATH}" ]] || [[ -n "${SCPPASS}" ]] || [[ -n "${REMOTETEMPLATE}" ]] || [[ -n "${REMOTETEMPLATE}" ]]; then
      echo "Logging"
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
      echo
    fi
    # Weekly Digests
    if [[ -n "${DIGESTEMAIL}" ]]; then
      echo "Weekly Digests"
      echo "--------------"
      [[ -n "${DIGESTEMAIL}" ]] && echo "Send to: ${DIGESTEMAIL}"
      echo
    fi
    # Monthly Reporting
    if [[ -n "${CLIENTCONTACT}" ]] || [[ -n "${INCLUDEHOSTING}" ]]; then
      echo "Monthly Reporting"
      echo "-----------------"
      [[ -n "${CLIENTCONTACT}" ]] && echo "Client contact: ${CLIENTCONTACT}"
      [[ -n "${INCLUDEHOSTING}" ]] && echo "Hosting notes: ${INCLUDEHOSTING}"
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
    if [[ -n "${CLIENTID}" ]] || [[ -n "${CLIENTSECRET}" ]] || [[ -n "${REDIRECTURI}" ]] || [[ -n "${AUTHORIZATIONCODE}" ]] || [[ -n "${ACCESSTOKEN}" ]] || [[ -n "${REFRESHTOKEN}" ]] || [[ -n "${PROFILEID}" ]]; then
      echo "Google Analytics"
      echo "----------------"
      [[ -n "${CLIENTID}" ]] && echo "Client ID: ${CLIENTID}"
      [[ -n "${CLIENTSECRET}" ]] && echo "Client secret: ${CLIENTSECRET}"
      [[ -n "${REDIRECTURI}" ]] && echo "Redirect URI: ${REDIRECTURI}"
      [[ -n "${AUTHORIZATIONCODE}" ]] && echo "Authorization code: ${AUTHORIZATIONCODE}"
      [[ -n "${ACCESSTOKEN}" ]] && echo "Access token: ${ACCESSTOKEN}"
      [[ -n "${REFRESHTOKEN}" ]] && echo "Refresh token: ${REFRESHTOKEN}"
      [[ -n "${PROFILEID}" ]] && echo "Profile ID: ${PROFILEID}"
      echo
    fi
    # Server monitoring
    if [[ -n "${MONITORURL}" ]] || [[ -n "${MONITORUSER}" ]] || [[ -n "${SERVERID}" ]]; then
      echo "Server Monitoring"
      echo "-----------------"
      [[ -n "${MONITORURL}" ]] && echo "Monitor URL: ${MONITORURL}"
      [[ -n "${MONITORUSER}" ]] && echo "User: ${MONITORUSER}"
      [[ -n "${SERVERID}" ]] && echo "Server ID: ${SERVERID}"
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
    if [[ "${POSTEMAILHEAD}${TASK}${POSTEMAILTAIL}" == ?*@?*.?* ]]; then
      console "Testing integration to ${POSTEMAIL}"
      (
      if [[ -z "${TASKUSER}" ]] || [[ -z "${ADDTIME}" ]]; then
        echo "From: ${FROM}"
      else
        echo "From: ${TASKUSER}"
      fi
      echo "Reply-To: ${FROM} <${FROM}>"
      echo "To: ${POSTEMAILHEAD}${TASK}${POSTEMAILTAIL}"
      echo "Subject: [TESTING] ${SUBJECT} - ${APP}"
      echo "Content-Type: text/plain"
      echo
      echo "This is a test email integration from stir ${VERSION}"
      echo "(https://github.com/EMRL/stir/)"
      echo
      [[ -n "${PROJNAME}" ]] && echo "Name: ${PROJNAME}"
      [[ -n "${PROJCLIENT}" ]] && echo "Client: ${PROJCLIENT}"
      [[ -n "${DEVURL}" ]] && echo "Staging URL: ${DEVURL}"
      [[ -n "${PRODURL}" ]] && echo "Production URL: ${PRODURL}"
      ) | "${sendmail_cmd}" -t
      quiet_exit
    else
      console "Integration email address ${POSTEMAILHEAD}${TASK}${POSTEMAILTAIL} does not look valid"; quiet_exit
    fi
  fi
}
