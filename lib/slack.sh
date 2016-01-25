#!/bin/bash
# slackPost()
#
# Integration with Slack!
trace "Loading slackPost()"

function slackPost () {
	# Format message as a code block ```${msg}```
	#SLACKMESSAGE="\`\`\`$1\`\`\`"
	#COMMITURL="http://disneyland.com"
	#SLACKMESSAGE="Updates made to ${PRODURL}\n<${COMMITURL}|${COMMITHASH}>: ${notes}"
	SLACKMESSAGE="Updates made to ${APP}\n<${COMMITURL}|${COMMITHASH}>: ${notes}"

	# Not being used yet - icons for different message states
	#case "$2" in
	#	INFO)
	#		SLACKICON=':slack:'
	#		;;
	#	WARNING)
	#		SLACKICON=':warning:'
	#		;;
	#	ERROR)
	#		SLACKICON=':bangbang:'
	#		;;
	#	*)
	#		SLACKICON=':slack:'
	#		;;
	#esac

	# Create payload 
	curl -X POST --data "payload={\"text\": \"${SLACKMESSAGE}\"}" ${SLACKURL}
}

# Test the integration
# slackPost > /dev/null 2>&1
# "For every action, there is an equal and opposite malfunction." "WARNING"
