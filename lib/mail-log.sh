#!/bin/bash
#
# mail-log.sh
#
###############################################################################
# Mail handling
###############################################################################
trace "Loading mail handler"

function mailLog() {
  # Only send email if a commit has been made, an approval is required, or there has been an error
  if [[ -n "${COMMITHASH}" ]] || [[ "${message_state}" == "ERROR" ]] || [[ "${message_state}" == "APPROVAL NEEDED" ]] || [[ "${AUTOMATE}" == "1" ]]; then

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
      ) | "${MAILPATH}"/sendmail -t
    else
      # Compile and send text format email
      textSendmail=$(<"${logFile}")
      (
      echo "Sender: ${FROM}"
      echo "From: ${FROM} <${FROM}>"
      echo "Reply-To: ${FROM} <${FROM}>"
      echo "To: ${TO}"
      echo "Subject: [${message_state}] ${SUBJECT} - ${APP}"          
      echo "Content-Type: text/plain"
      echo
      echo "${textSendmail}";
      ) | "${MAILPATH}"/sendmail -t
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
    ) | "${MAILPATH}"/sendmail -t
  fi
}

function emailTest() {
  console "Testing email..."
  if [[ -z "${TO}" ]]; then
    warning "No recipient address found."; emptyLine
    cleanUp; exit 1
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
    echo "This is a test HTML email from <a href=\"https://github.com/EMRL/deploy/\">deploy ${VERSION}</a>.<br />"
    echo "Current user is ${DEV}<br /><br />";
    echo
    echo "<strong>Project Information</strong><br />"
    echo "Name: ${PROJNAME}<br />"
    echo "Client: ${PROJCLIENT}<br />"
    echo "Logo: ${CLIENTLOGO}<br />"
    echo "Digest email(s): ${DIGESTEMAIL}<br />"
    echo "Staging URL: ${DEVURL}<br />"
    echo "Production URL: ${PRODURL}<br /><br />"
    echo
    echo "<strong>Git Configuration</strong><br />"
    echo "Repo: ${REPOHOST}/${REPO}<br />"
    echo "Master branch: ${MASTER}<br />"
    echo "Production branch: ${PRODUCTION}<br />"
    echo "Auto merge: ${AUTOMERGE}<br />"
    echo "File Stashing: ${STASH}<br />"
    echo "Force branch checking: ${CHECKBRANCH}<br /><br />"
    echo
    echo "<strong>Wordpress Setup</strong><br />"
    echo "Wordpress root: ${WPROOT}<br />"
    echo "Wordpress application: ${WPAPP}<br />"
    echo "Wordpress system: ${WPSYSTEM}<br /><br />"
    echo
    echo "<strong>Deployment Configuration</strong><br />"
    echo "Deploy command: ${DEPLOY}<br />"
    echo "Disallow deployment: ${DONOTDEPLOY}<br /><br />"
    echo 
    echo "<strong>Integration</strong><br />"
    echo "Task #: ${TASK}<br />"
    echo "Task user: ${TASKUSER}<br />"
    echo "Task time: ${ADDTIME}<br />"
    echo "Post to Slack: ${POSTTOSLACK}<br />"
    echo "Post errors to Slack: ${SLACKERROR}<br />"
    echo "Google Analytics ID: ${PROFILEID}";
    ) | "${MAILPATH}"/sendmail -t
    # Send Text mail
    (
    echo "Sender: ${FROM}"
    echo "From: ${FROM} <${FROM}>"
    echo "Reply-To: ${FROM} <${FROM}>"
    echo "To: ${TO}"
    echo "Subject: [TESTING] ${SUBJECT} - ${APP}"
    echo "Content-Type: text/plain"
    echo
    echo "This is a test TEXT email from deploy ${VERSION} (https://github.com/EMRL/deploy/)"
    echo "Current user is ${DEV}";
    echo
    echo "Project Information"
    echo "-------------------"
    echo "Name: ${PROJNAME}"
    echo "Client: ${PROJCLIENT}"
    echo "Logo: ${CLIENTLOGO}"
    echo "Digest email(s): ${DIGESTEMAIL}"
    echo "Staging URL: ${DEVURL}"
    echo "Production URL: ${PRODURL}"
    echo
    echo "Git Configuration"
    echo "-----------------"
    echo "Repo: ${REPOHOST}/${REPO}"
    echo "Master branch: ${MASTER}"
    echo "Production branch: ${PRODUCTION}"
    echo "Auto merge: ${AUTOMERGE}"
    echo "File Stashing: ${STASH}"
    echo "Force branch checking: ${CHECKBRANCH}"
    echo
    echo "Wordpress Setup"
    echo "-----------------------"
    echo "Wordpress root: ${WPROOT}"
    echo "Wordpress application: ${WPAPP}"
    echo "Wordpress system: ${WPSYSTEM}"
    echo
    echo "Deployment Configuration"
    echo "------------------------"
    echo "Deploy command: ${DEPLOY}"
    echo "Disallow deployment: ${DONOTDEPLOY}"
    echo 
    echo "Integration"
    echo "-----------"
    echo "Task #: ${TASK}"
    echo "Task user: ${TASKUSER}"
    echo "Task time: ${ADDTIME}"
    echo "Post to Slack: ${POSTTOSLACK}"
    echo "Post errors to Slack: ${SLACKERROR}"
    echo "Google Analytics ID: ${PROFILEID}";
    ) | "${MAILPATH}"/sendmail -t
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
      echo "This is a test email integration from deploy ${VERSION}"
      echo "(https://github.com/EMRL/deploy/)"
      ) | "${MAILPATH}"/sendmail -t
      quietExit
    else
      console "Integration email address ${POSTEMAILHEAD}${TASK}${POSTEMAILTAIL} does not look valid"; quietExit
    fi
  fi
}
