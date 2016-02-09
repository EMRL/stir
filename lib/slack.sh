#!/bin/bash
# slackPost()
#
# Integration with Slack!
trace "Loading slackPost()"

function slackPost () {
	# Format the message 
	if [ "${message_state}" == "ERROR" ]; then
		if [ -z "$notes" ]; then
			notes="Something went wrong."
		fi
		slack_message="${USER} attempted to deploy changes to ${APP}\nERROR: *${error_msg}*"
	else
		slack_message="${USER} deployed updates to ${APP}\n<${COMMITURL}|${COMMITHASH}>: ${notes}"
	fi

#	slack_message="${USER} deployed updates to ${APP}\n<${COMMITURL}|${COMMITHASH}>: ${notes}"

	# Set icon for message state
	case "${message_state}" in
 		ERROR)
 			slack_icon=':warning:'
 			;;
 		*)
 			slack_icon=''
 			;;
	esac

	# Create payload 
	curl -X POST --data "payload={\"text\": \"${slack_icon} ${slack_message}\"}" ${SLACKURL} > /dev/null 2>&1
}

function slackTest {
	console "Testing Slack integration..."
	curl -X POST --data "payload={\"text\": \"${slack_icon} Testing Slack integration from deploy ${VERSION}\nhttps://github.com/EMRL/deploy\"}" ${SLACKURL}
	emptyLine
}
