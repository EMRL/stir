#!/usr/bin/env bash
#
# webhook.sh
#
###############################################################################
# Webhook POST functionality
###############################################################################

function post_webhook {
  if [[ -n "${POST_URL}" ]]; then
    # Create payload for digests
    if [[ "${DIGEST}" == "1" ]] && [[ -n "${GREETING}" ]]; then
      message_state="DIGEST"
      payload="*${PROJECT_NAME}* updates for the week of ${WEEKOF} (<${DIGESTURL})"               
      # Send it
      "${curl_cmd}" -X POST --data "payload={\"text\": \"${payload}\"}" "${POST_URL}" > /dev/null 2>&1; error_status
    fi

    # Create payload for reports
    if [[ "${REPORT}" == "1" ]]; then
      payload="Monthly report for *${PROJECT_NAME}* created (<${REPORTURL})" 
      "${curl_cmd}" -X POST --data "payload={\"text\": \"${payload}\"}" "${POST_URL}" > /dev/null 2>&1; error_status              
    fi
  fi
}

# Webhook configuration test
function TEST_WEBHOOK {
  console "Testing POST integration..."
  echo "${POST_URL}"
  if [[ -z "${POST_URL}" ]]; then
    warning "No webhook URL found."; empty_line
    clean_up; exit 1
  else
    "${curl_cmd}" -X POST --data "payload={\"text\": \"Testing POST integration of ${APP} from stir ${VERSION}\nhttps://github.com/EMRL/stir\"}" "${POST_URL}"
    empty_line
  fi
}
