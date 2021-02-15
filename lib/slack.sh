#!/usr/bin/env bash
#
# slack.sh
#
###############################################################################
# Integration with Slack
###############################################################################

function post_slack () {

  # If running in --automate, change the user name
  if [[ "${AUTOMATE}" == "1" ]]; then
    SLACKUSER="Scheduled update:"
  else
    SLACKUSER="${USER}"
  fi

  # If using --current, use the REPO value instead of the APP (current directory)
  if [[ "${CURRENT}" == "1" ]]; then
    APP="${REPO}"
  fi

  # Setup the payload w/ the baseline language
  slack_message="*${SLACKUSER}* (${DEV}) pushed updates to ${APP}"

  # Is this a simple publish of existing code to live?
  if [[ "${PUBLISH}" == "1" ]]; then
    if [[ -z "${PROD_URL}" ]]; then
      slack_message="*${SLACKUSER}* (${DEV}) published commit <${COMMITURL}|${COMMITHASH}> to ${APP}"
    else
      slack_message="*${SLACKUSER}* (${DEV}) published commit <${COMMITURL}|${COMMITHASH}> to <${PROD_URL}|${APP}>"
    fi
  fi  

  # Does this need approval?
  if [[ "${REQUIRE_APPROVAL}" == "TRUE" ]] && [[ "${APPROVE}" != "1" ]] && [[ "${DENY}" != "1" ]] && [[ "${DIGEST}" != "1" ]]; then
    slack_message="*${SLACKUSER}* queued updates to <${DEV_URL}|${APP}> for approval"
  fi

  # Is this being approved?
  if [[ "${APPROVE}" == "1" ]]; then
    if [[ -z "${PROD_URL}" ]]; then
      slack_message="*${SLACKUSER}* approved updates <${COMMITURL}|${COMMITHASH}> and deployed to ${APP}"
    else
      slack_message="*${SLACKUSER}* approved updates <${COMMITURL}|${COMMITHASH}> and deployed to <${PROD_URL}|${APP}>"
    fi
  fi      

  # This is broken
  # if [[ "${PUBLISH}" != "1" ]] && [[ "${AUTOMATE}" != "1" ]] && [[ -n "${notes}" ]] && [[ "${APPROVE}" != "1" ]]; then

  # If there's a commit, AND there are notes/commit message. spam this
  if [[ -n "${notes}" ]] && [[ -n "${COMMITHASH}" ]]; then
    # Is this a queue for approval?
    if [[ "${REQUIRE_APPROVAL}" == "TRUE" ]] && [[ "${APPROVE}" != "1" ]] && [[ "${DENY}" != "1" ]]; then
      slack_message="${slack_message}\nProposed commit message: ${notes}"
    else
      slack_message="${slack_message}\n<${COMMITURL}|${COMMITHASH}>: ${notes}"
    fi
  fi

  # Has there been an error?
  if [[ "${message_state}" == "ERROR" ]]; then
    if [ -z "${notes}" ]; then
      notes="Something went wrong."
    fi
    slack_message="*${SLACKUSER}* (${DEV}) attempted to make changes to ${APP}\nERROR: ${error_msg}"
  fi

  # Is there nothing to do?
  if [[ "${message_state}" == "NOTICE" ]]; then
    slack_message="*${SLACKUSER}* (${DEV}) nothing to do for ${APP}\nNOTICE: ${notes}"
  fi

  # Create a payload for invoices
  if [[ "${CREATE_INVOICE}" == "1" ]]; then
    message_state="NOTICE"
    # Does a production URL exit?
    if [[ -n "${PROD_URL}" ]]; then 
      slack_message="${IN_NOTES} invoice (#${current_invoice}) created for <${PROD_URL}|${PROJECT_NAME}>"
    else 
      slack_message="${IN_NOTES} invoice (#${current_invoice}) created for *${PROJECT_NAME}*"               
    fi    
  fi

  # Add a details link to online log_files if they exist
  if [[ -n "${REMOTE_URL}" ]] && [[ -n "${REMOTE_LOG}" ]] && [[ "${CREATE_INVOICE}" != "1" ]] && [[ -n "${LOGURL}" ]]; then
    slack_message="${slack_message} (<${LOGURL}|Details>)"
  fi

  # Create payload for reports
  if [[ "${REPORT}" == "1" ]] || [[ "${CREATE_INVOICE}" == "1" && "${}" ]]; then
    if [[ -n "${PROD_URL}" ]]; then 
      slack_message="Monthly report for <${PROD_URL}|${PROJECT_NAME}> created (<${REPORTURL}|View>)"
    else
      slack_message="Monthly report for *${PROJECT_NAME}* created (<${REPORTURL}|View>)"               
    fi
  fi

  # Create payload for digests
  if [[ "${DIGEST}" == "1" ]] && [[ -n "${DIGESTURL}" ]] && [[ -n "${GREETING}" ]]; then
    if [[ -n "${DIGEST_SLACK}" ]] && [[ "${DIGEST_SLACK}" != "FALSE" ]]; then
      message_state="DIGEST"
      if [[ "${DIGEST_SLACK}" == *"slack"* ]]; then
        SLACK_URL="${DIGEST_SLACK}"
      fi
      # Does a production URL exit?
      if [[ -n "${PROD_URL}" ]]; then 
        slack_message="<${PROD_URL}|${PROJECT_NAME}> updates for the week of ${WEEKOF} (<${DIGESTURL}|View>)"
      else
        slack_message="*${PROJECT_NAME}* updates for the week of ${WEEKOF} (<${DIGESTURL}|View>)"               
      fi
        else
      return
    fi
  fi

  # Arf I hate this
  if [[ "${SCAN}" == "1" ]]; then
    slack_message="${notes} (<${LOGURL}|Details>)"
  fi

  # Set icon for message state
  case "${message_state}" in
    ERROR)
      slack_icon=':no_entry:'
      ;;
    DIGEST)
      slack_icon=':black_small_square:'
      ;;
    PASSED)
      slack_icon=':heavy_check_mark:'
      ;;
    *)
      slack_icon=''
      ;;
  esac

  # Send payload
  if [[ "${DIGEST}" == "1" ]] && [[ -z "${GREETING}" ]]; then
    trace "No activity found, canceling digest."
  else
    "${curl_cmd}" -X POST --data "payload={\"text\": \"${slack_icon} ${slack_message}\"}" "${SLACK_URL}" > /dev/null 2>&1; error_status
  fi
}

# Slack configuration test
function slack_test {
  console "Testing Slack integration..."
  echo "${SLACK_URL}"
  if [[ -z "${SLACK_URL}" ]]; then
    warning "No Slack configuration found."; empty_line
    clean_up; exit 1
  else
    "${curl_cmd}" -X POST --data "payload={\"text\": \"${slack_icon} Testing Slack integration of ${APP} from stir ${VERSION}\nhttps://github.com/EMRL/stir\"}" "${SLACK_URL}"
    empty_line
  fi
}
