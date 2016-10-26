#!/bin/bash
# slackPost()
#
# Integration with Slack!
trace "Loading Slack integration"

function slackPost () {
	# Format the message 
	if [ "${message_state}" == "ERROR" ]; then
		if [ -z "${notes}" ]; then
			notes="Something went wrong."
		fi
		slack_message="${USER} attempted to deploy changes to ${APP}\nERROR: *${error_msg}*"
	else
		# Add a link to the online logs, if they are setup.
		if [ -n "${REMOTEURL}" ] && [ -n "${REMOTELOG}" ] ; then
			slack_message="${USER} deployed updates to ${APP} (<${REMOTEURL}/${APP}${COMMITHASH}.html|Details>)\n<${COMMITURL}|${COMMITHASH}>: ${notes}"
		else
			slack_message="${USER} deployed updates to ${APP}\n<${COMMITURL}|${COMMITHASH}>: ${notes}"
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
	curl -X POST --data "payload={\"text\": \"${slack_icon} ${slack_message}\"}" "${SLACKURL}" > /dev/null; errorStatus # 2>&1; errorStatus
}

function slackTest {
	console "Testing Slack integration..."
	if [[ -z "${SLACKURL}" ]]; then
		warning "No Slack configuration found."; emptyLine
		cleanUp; exit 1
	else
		curl -X POST --data "payload={\"text\": \"${slack_icon} Testing Slack integration of ${APP} from deploy ${VERSION}\nhttps://github.com/EMRL/deploy\"}" "${SLACKURL}"
		emptyLine
	fi
}
