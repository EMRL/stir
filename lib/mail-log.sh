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
   	[[ -n "${PROJNAME}" ]] && echo "Name: ${PROJNAME}<br />"
    [[ -n "${PROJCLIENT}" ]] && echo "Client: ${PROJCLIENT}<br />"
    [[ -n "${CLIENTLOGO}" ]] && echo "Logo: ${CLIENTLOGO}<br />"
    [[ -n "${DIGESTEMAIL}" ]] && echo "Digest email(s): ${DIGESTEMAIL}<br />"
    [[ -n "${DEVURL}" ]] && echo "Staging URL: ${DEVURL}<br />"
    [[ -n "${PRODURL}" ]] && echo "Production URL: ${PRODURL}<br />"
    echo "<br />"
    # Git
    if [[ -n "${REPO}" ]] || [[ -n "${MASTER}" ]] || [[ -n "${PRODUCTION}" ]] || [[ -n "${AUTOMERGE}" ]] || [[ -n "${STASH}" ]] || [[ -n "${CHECKBRANCH}" ]]; then
	    echo "<strong>Git Configuration</strong><br />"
	    [[ -n "${REPO}" ]] && echo "Repo: ${REPOHOST}/${REPO}<br />"
	    [[ -n "${MASTER}" ]] && echo "Master branch: ${MASTER}<br />"
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
  	# Integration
	  if [[ -n "${TASK}" ]] || [[ -n "${TASKUSER}" ]] || [[ -n "${ADDTIME}" ]] || [[ -n "${POSTTOSLACK}" ]] || [[ -n "${SLACKERROR}" ]] || [[ -n "${PROFILEID}" ]] || [[ -n "${POSTURL}" ]]; then
	    echo "<strong>Integration</strong><br />"
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
			[[ -n "${REMOTELOG}" ]] && echo "Web logs: ${REMOTELOG}<br />"
			[[ -n "${REMOTEURL}" ]] && echo "Address: ${REMOTEURL} <br />"
			[[ -n "${EXPIRELOGS}" ]] && echo "Log expiration: ${EXPIRELOGS} days <br />"
			[[ -n "${LOCALHOSTPOST}" ]] && echo "Save logs locally: ${LOCALHOSTPOST}<br />"
			[[ -n "${LOCALHOSTPATH}" ]] && echo "Path to local logs: ${}LOCALHOSTPATH<br />"
			[[ -n "${SCPPOST}" ]] && echo "Post with SCP/SSH: ${SCPPOST}<br />"
			[[ -n "${SCPUSER}" ]] && echo "SCP user: ${SCPUSER}<br />"
			[[ -n "${SCPHOST}" ]] && echo "Remote log host: ${SCPHOST}<br />"
			[[ -n "${SCPHOSTPATH}" ]] && echo "Remote log path: ${SCPHOSTPATH}<br />"
			[[ -n "${REMOTETEMPLATE}" ]] && echo "Log template: ${REMOTETEMPLATE}<br />"
			echo "<br />"
		fi
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
   	[[ -n "${PROJNAME}" ]] && echo "Name: ${PROJNAME}"
    [[ -n "${PROJCLIENT}" ]] && echo "Client: ${PROJCLIENT}"
    [[ -n "${CLIENTLOGO}" ]] && echo "Logo: ${CLIENTLOGO}"
    [[ -n "${DIGESTEMAIL}" ]] && echo "Digest email(s): ${DIGESTEMAIL}"
    [[ -n "${DEVURL}" ]] && echo "Staging URL: ${DEVURL}"
    [[ -n "${PRODURL}" ]] && echo "Production URL: ${PRODURL}"
    echo 
    # Git
    if [[ -n "${REPO}" ]] || [[ -n "${MASTER}" ]] || [[ -n "${PRODUCTION}" ]] || [[ -n "${AUTOMERGE}" ]] || [[ -n "${STASH}" ]] || [[ -n "${CHECKBRANCH}" ]]; then
	    echo "Git Configuration"
	    echo "-----------------"
	    [[ -n "${REPO}" ]] && echo "Repo: ${REPOHOST}/${REPO}"
	    [[ -n "${MASTER}" ]] && echo "Master branch: ${MASTER}"
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
  	# Integration
	  if [[ -n "${TASK}" ]] || [[ -n "${TASKUSER}" ]] || [[ -n "${ADDTIME}" ]] || [[ -n "${POSTTOSLACK}" ]] || [[ -n "${SLACKERROR}" ]] || [[ -n "${PROFILEID}" ]] || [[ -n "${POSTURL}" ]]; then
	    echo "Integration"
	    echo "-----------"
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
			[[ -n "${REMOTELOG}" ]] && echo "Web logs: ${REMOTELOG}"
			[[ -n "${REMOTEURL}" ]] && echo "Address: ${REMOTEURL}"
			[[ -n "${EXPIRELOGS}" ]] && echo "Log expiration: ${EXPIRELOGS} days"
			[[ -n "${LOCALHOSTPOST}" ]] && echo "Save logs locally: ${LOCALHOSTPOST}"
			[[ -n "${LOCALHOSTPATH}" ]] && echo "Path to local logs: ${}LOCALHOSTPATH"
			[[ -n "${SCPPOST}" ]] && echo "Post with SCP/SSH: ${SCPPOST}"
			[[ -n "${SCPUSER}" ]] && echo "SCP user: ${SCPUSER}"
			[[ -n "${SCPHOST}" ]] && echo "Remote log host: ${SCPHOST}"
			[[ -n "${SCPHOSTPATH}" ]] && echo "Remote log path: ${SCPHOSTPATH}"
			[[ -n "${REMOTETEMPLATE}" ]] && echo "Log template: ${REMOTETEMPLATE}s"
			echo
		fi


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
