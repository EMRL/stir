#!/bin/bash
# slackPost()
#
# Integration with Slack!
trace "Loading slackPost()"

function slackPost () {
	# Format the message 
	SLACKMESSAGE="${USER} deployed updates to ${APP}\n<${COMMITURL}|${COMMITHASH}>: ${notes}"
	# Create payload 
	curl -X POST --data "payload={\"text\": \"${SLACKMESSAGE}\"}" ${SLACKURL}
}

function slackTest {
	console "Testing Slack integration..."
	curl -X POST --data "payload={\"text\": \"Testing Slack integration from deploy ${VERSION}\nhttps://github.com/EMRL/deploy\"}" ${SLACKURL}
	emptyLine
}
