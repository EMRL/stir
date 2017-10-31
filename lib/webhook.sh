#!/bin/bash
#
# webhook.sh
#
###############################################################################
# Webhook POST functionality
###############################################################################
trace "Loading webhooks"

function postWebhook {
	if [[ -n "${POSTURL}" ]]; then
		# Create payload for digests
	  if [[ "${DIGEST}" == "1" ]] && [[ -n "${GREETING}" ]]; then
      message_state="DIGEST"
      payload="*${PROJNAME}* updates for the week of ${WEEKOF} (<${DIGESTURL})"               
      # Send it
	    curl -X POST --data "payload={\"text\": \"${payload}\"}" "${POSTURL}" > /dev/null 2>&1; errorStatus
		fi
  fi
}

# Webhook configuration test
function postTest {
	console "Testing POST integration..."
	echo "${POSTURL}"
	if [[ -z "${POSTURL}" ]]; then
	warning "No webhook URL found."; emptyLine
	cleanUp; exit 1
	else
	curl -X POST --data "payload={\"text\": \"Testing POST integration of ${APP} from deploy ${VERSION}\nhttps://github.com/EMRL/deploy\"}" "${POSTURL}"
	emptyLine
	fi
}
