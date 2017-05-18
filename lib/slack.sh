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

	# If using --current, use the REPO value instead of the APP (current directory)
	if [[ "${CURRENT}" == "1" ]]; then
		APP="${REPO}"
	fi

	# Setup the payload w/ the baseline language
	slack_message="*${SLACKUSER}* deployed updates to ${APP}"

	# Is this a simple publish of existing code to live?
	if [[ "${PUBLISH}" == "1" ]]; then
		if [[ -z "${PRODURL}" ]]; then
			slack_message="*${SLACKUSER}* published commit <${COMMITURL}|${COMMITHASH}> to ${APP}"
		else
			slack_message="*${SLACKUSER}* published commit <${COMMITURL}|${COMMITHASH}> to <${PRODURL}|${APP}>"
		fi
	fi	

	# Does this need approval?
	if [[ "${REQUIREAPPROVAL}" == "TRUE" ]] && [[ "${APPROVE}" != "1" ]] && [[ "${DENY}" != "1" ]]; then
		slack_message="*${SLACKUSER}* queued updates to <${DEVURL}|${APP}> for approval"
	fi

	# Is this being approved?
	if [[ "${APPROVE}" == "1" ]]; then
		if [[ -z "${PRODURL}" ]]; then
			slack_message="*${SLACKUSER}* approved updates <${COMMITURL}|${COMMITHASH}> and deployed to ${APP}"
		else
			slack_message="*${SLACKUSER}* approved updates <${COMMITURL}|${COMMITHASH}> and deployed to <${PRODURL}|${APP}>"
		fi
	fi		

	# This is broken
	# if [[ "${PUBLISH}" != "1" ]] && [[ "${AUTOMATE}" != "1" ]] && [[ -n "${notes}" ]] && [[ "${APPROVE}" != "1" ]]; then

	# If there's a commit, AND there are notes/commit message. spam this
	if [[ -n "${notes}" ]] && [[ -n "${COMMITHASH}" ]]; then
		# Is this a queue for approval?
		if [[ "${REQUIREAPPROVAL}" == "TRUE" ]] && [[ "${APPROVE}" != "1" ]] && [[ "${DENY}" != "1" ]]; then
			slack_message="${slack_message}\nProposed commit message: ${notes}"
		else
			slack_message="${slack_message}\n<${COMMITURL}|${COMMITHASH}>: ${notes}"
		fi
	fi

	# Has there been an error?
	if [ "${message_state}" == "ERROR" ]; then
		if [ -z "${notes}" ]; then
			notes="Something went wrong."
		fi
		slack_message="*${SLACKUSER}* attempted to deploy changes to ${APP}\nERROR: ${error_msg}"
	fi

	# Has there been an error?
	if [ "${message_state}" == "NOTICE" ]; then
		slack_message="*${SLACKUSER}* nothing to do for ${APP}\nNOTICE: ${notes}"
	fi

	# Add a details link to online logfiles if they exist
	if [[ -n "${REMOTEURL}" ]] && [[ -n "${REMOTELOG}" ]]; then
		slack_message="${slack_message} (<${LOGURL}|Details>)"
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
	if [[ "${DIGEST}" != "1" ]]; then
		curl -X POST --data "payload={\"text\": \"${slack_icon} ${slack_message}\"}" "${SLACKURL}" > /dev/null 2>&1; errorStatus
	fi
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
