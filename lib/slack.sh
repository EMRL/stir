#!/bin/bash
# slackPost()
#
# Integration with Slack!
trace "Loading Slack integration"

function slackPost () {
	# If running in --automate, change the user name
	if [ "$AUTOMATE" = "1" ]; then
		SLACKUSER="Scheduled update:"
	else
		SLACKUSER=${USER}
	fi
	
	# Format the message 
	if [ "${message_state}" == "ERROR" ]; then
		if [ -z "${notes}" ]; then
			notes="Something went wrong."
		fi
		slack_message="${SLACKUSER} attempted to deploy changes to ${APP}\nERROR: *${error_msg}*"
	else

		# Add a link to the online logs, if they are setup.
		if [ -n "${REMOTEURL}" ] && [ -n "${REMOTELOG}" ] ; then
			if [ "${APPROVE}" == "1" ] && [ -n "${PRODURL}" ]; then
				slack_message="${SLACKUSER} approved updates to <${PRODURL}|${APP}> and published commit <${COMMITURL}|${COMMITHASH}> (<${REMOTEURL}/${APP}${COMMITHASH}.html|Details>)"
			else
				slack_message="${SLACKUSER} deployed updates to ${APP} (<${REMOTEURL}/${APP}${COMMITHASH}.html|Details>)\n<${COMMITURL}|${COMMITHASH}>: ${notes}"
			fi
		else
			if [ "${APPROVE}" == "1" ] && [ -n "${PRODURL}" ]; then
				slack_message="${SLACKUSER} approved updates to <${PRODURL}|${APP}> and published commit <${COMMITURL}|${COMMITHASH}>"
			else
				slack_message="${SLACKUSER} deployed updates to ${APP}\n<${COMMITURL}|${COMMITHASH}>: ${notes}"
			fi
		fi
	fi

	# Set icon for message state
	case "${message_state}" in
 		ERROR)
 			slack_icon=':warning:'
 			;;
 		*)
 			slack_icon=''
 			;;
	esac

	# Send payload 
	curl -X POST --data "payload={\"text\": \"${slack_icon} ${slack_message}\"}" "${SLACKURL}" > /dev/null 2>&1; errorStatus
}

function slackTest {
	console "Testing Slack integration..."
	echo "${SLACKURL}"
	if [[ -z "${SLACKURL}" ]]; then
		warning "No Slack configuration found."; emptyLine
		cleanUp; exit 1
	else
		curl -X POST --data "payload={\"text\": \"${slack_icon} Testing Slack integration of ${APP} from deploy ${VERSION}\nhttps://github.com/EMRL/deploy\"}" "${SLACKURL}"
		emptyLine
	fi
}
