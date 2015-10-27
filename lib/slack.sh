#!/bin/bash
# smrtCommit()
#
# Check to see if production environment is online and running its Apache server
function slackPost () {
	# Format message as a code block ```${msg}```
	#SLACKMESSAGE="\`\`\`$1\`\`\`"
	SLACKMESSAGE="$1"
	# Move this to master config, it's only here for testing
	SLACKURL=https://hooks.slack.com/services/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

	# Icons for different message states
	case "$2" in
		INFO)
			SLACKICON=':slack:'
			;;
		WARNING)
			SLACKICON=':warning:'
			;;
		ERROR)
			SLACKICON=':bangbang:'
			;;
		*)
			SLACKICON=':slack:'
			;;
	esac

	# Create payload 
	curl -X POST --data "payload={\"text\": \"${SLACKICON} ${SLACKMESSAGE}\"}" ${SLACKURL}
}

# Test the integration
# slackPost "For every action, there is an equal and opposite malfunction." "WARNING"