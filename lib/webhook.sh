#!/bin/bash
#
# webhook.sh
#
###############################################################################
# Webhook POST functionality
###############################################################################
trace "Loading webhooks"

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
