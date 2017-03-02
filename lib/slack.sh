#!/bin/bash
# slackPost()
#
# Integration with Slack!
trace "Loading Slack integration"

function slackPost () {
	# If running in --automate, change the user name
	if [[ "$AUTOMATE" == "1" ]]; then
		SLACKUSER="Scheduled update:"
	else
		SLACKUSER=${USER}
	fi

	# Setup the payload w/ the baseline language
	slack_message="*${SLACKUSER}* deployed updates to ${APP}"

	# Is this a simple publish of existing code to live?
	if [[ "${PUBLISH}" == "1" ]]; then
		slack_message="*${SLACKUSER}* published the current production codebase (commit <${COMMITURL}|${COMMITHASH}>) to <${PRODURL}|${APP}>"
	fi	

	# Does this need approval?
	if [[ "${REQUIREAPPROVAL}" == "TRUE" ]] && [[ "${APPROVE}" != "1" ]]; then
		slack_message="*${SLACKUSER}* queued updates to <${DEVURL}|${APP}> for approval"
	fi

	# Is this being approved?
	if [[ "${APPROVE}" == "1" ]]; then
		slack_message="*${SLACKUSER}* approved updates <${COMMITURL}|${COMMITHASH}> and deployed to <${PRODURL}|${APP}>"
	fi		

	# Add a details link to online logfiles if they exist
	if [[ -n "${REMOTEURL}" ]] && [[ -n "${REMOTELOG}" ]]; then
		slack_message="${slack_message} (<${REMOTEURL}/${APP}${COMMITHASH}.html|Details>)"
	fi

	if [[ "${PUBLISH}" != "1" ]] && [[ "${AUTOMATE}" != "1" ]] && [[ -n "${notes}" ]] && [[ "${APPROVE}" != "1" ]]; then
		slack_message="${slack_message}\n<${COMMITURL}|${COMMITHASH}>: ${notes}"
	fi

	# Has there been an error?
	if [ "${message_state}" == "ERROR" ]; then
		if [ -z "${notes}" ]; then
			notes="Something went wrong."
		fi
		slack_message="*${SLACKUSER}* attempted to deploy changes to ${APP}\nERROR: ${error_msg}"
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
