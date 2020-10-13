#!/usr/bin/env bash
#
# quit.sh
#
###############################################################################
# Handles exiting the program
###############################################################################

# Clean exit
function clean_exit() {
  notice "Closing ${APP} (${REPOHOST}/${REPO})"
  make_log # Compile log
  # Check email settings
  if [[ "${EMAILSUCCESS}" == "TRUE" ]]; then
     mail_log
  fi

  # Is Slack integration configured?
  # Ghetto but will do for now
  if [[ "${POSTTOSLACK}" == "TRUE" ]] && [[ "${AUTOMATE}" == "1" ]] && [[ "${APPROVE}" != "1" ]] && [[ "${UPD1}" = "1" ]] && [[ "${UPD2}" = "1" ]]; then
    message_state="NOTICE"
    notes="No updates available for deployment"
    post_slack
  else
    if [[ "${POSTTOSLACK}" == "TRUE" ]]; then
      build_log; post_slack > /dev/null 2>&1
    fi
  fi

  # Fire webhook
  post_webhook

  # Clean up your mess
  clean_up; exit 0
}

# Exit on error
function error_exit() {
  notice "Closing ${APP} (${REPOHOST}/${REPO})"
  message_state="ERROR"; make_log # Compile log
  # Check email settings
  if [[ "${EMAILERROR}" == "TRUE" ]] || [[ -n "${sendmail_cmd}" ]]; then
    mail_log
  fi

  # Check Slack settings
  if [[ "${POSTTOSLACK}" == "TRUE" ]] && [[ "${SLACKERROR}" == "TRUE" ]]; then
    message_state="ERROR"
    post_slack
  fi

  # Clean up your mess
  clean_up; exit 1
}

# User interrupted exit
function user_exit() {
  rm "${WORKPATH}/${APP}/.git/index.lock" &> /dev/null
  trace "Exit on user request"
  # Check email settings
  if [[ "${EMAILQUIT}" == "TRUE" ]]; then
     mail_log
  fi
  # Clean up your mess
  clean_up; exit 0
}

# Quiet exit, never send log. Ever.
function quiet_exit() {
  # Clean up your mess
  clean_up; exit 0
}

# Clean everything up 
function clean_up() {
  # If anything is stashed, unstash it.
  if [[ "${current_stash}" == "1" ]]; then
    trace "Unstashing files"
    git stash pop >> "${log_file}"
    current_stash="0"
  fi  

  # Remove temporary files
  temp_files remove

  # Make sure we leave the repo as we found it
  if [[ -n "${start_branch}" ]]; then
    current_branch="$(git rev-parse --abbrev-ref HEAD)"
    if [[ "${current_branch}" != "${start_branch}" ]]; then
      git checkout "${start_branch}" &>> "${log_file}" &
    fi
  fi

  # If Wordfence was an issue, restart the plugin
  if [[ "${WFOFF}" = "1" ]]; then
    "${wp_cmd}" plugin activate --no-color wordfence &>> $log_file; error_check
  fi

  # Was this an approval?
  if [[ "${APPROVE}" == "1" ]]; then
    if [[ -f "${WORKPATH}/${APP}/.queued" ]] && [[ "${message_state}" != "ERROR" ]]; then 
      rm "${WORKPATH}/${APP}/.queued"
    fi
    if [[ -f "${WORKPATH}/${APP}/.approved" ]]; then
      rm "${WORKPATH}/${APP}/.approved"
    fi
  fi

  # Do we need to shutdown local wp server?
  if [[ -n "${PREPARE}" ]]; then
    WP_SERVER_PID=$(lsof -i :8080  | sed -n '1!p' | awk '{print $2}')
    if [[ -n "${WP_SERVER_PID}" ]]; then
      kill -9 "${WP_SERVER_PID}"  &> /dev/null
    fi
  fi
  
  # Attempt to reset the console when running --quiet
  if [[ "${QUIET}" != "1" ]]; then
    tput cnorm
  fi

  # Say goodnight, Gracie. Goodnight Gracie.
  console "Exiting."
}
