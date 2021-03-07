#!/usr/bin/env bash
#
# log-handling.sh
#
###############################################################################
# Handles parsing and creating logs
###############################################################################

function make_log() {
  # Clean up stuff that is most likely there
  sed -i -e '/git reset HEAD/d' \
    -e '/Checking out files:/d' \
    -e '/Unpacking objects:/d' \
    "${log_file}"

  # Clean up stuff that has a small chance of being there
  sed -i -e '/--:--:--/d'  \
    -e '/% Received/d' \
    -e '/\Dload/d' \
    -e '/\[34m/d' \
    -e '/\[31m/d' \
    -e '/\[32m/d' \
    -e '/\[96m/d' \
    -e '/no changes added to commit/d' \
    -e '/to update what/d' \
    -e '/to discard changes/d' \
    -e '/Changes not staged for/d' \
    "${log_file}"

  # Clean up mina's goobers
  if [[ "${DEPLOY}" == *"mina"* ]]; then
    sed -i -e '/0m Creating a temporary build path/c\Creating a temporary build path' \
      -e '/0m Fetching new git commits/c\Fetching new git commits' \
      -e '/0m Using git branch ${PRODUCTION}/c\Using git branch ${PRODUCTION}' \
      -e '/0m Using this git commit/c\Using this git commit' \
      -e '/0m Cleaning up old releases/c\Cleaning up old releases' \
      -e '/0m Build finished/c\Build finished' \
      "${log_file}"

    # Totally remove these lines
    sed -i -e "/----->/d" "${log_file}" \
      -e "/0m/d" "${log_file}" \
      -e "/Resolving deltas:/d" "${log_file}" \
      -e "/remote:/d" "${log_file}" \
      -e "/Receiving objects:/d" "${log_file}" \
      -e "/Resolving deltas:/d" "${log_file}" \
      -e "/No Kerberos credentials available/d" \
      "${log_file}"

    # If incognito, remove this stuff for privacy
    if [[ "${INCOGNITO}" == "TRUE" ]]; then
      sed -i "/Using cached file/d" "${log_file}"
    fi
  fi

  # Filter out ACF license key & wget stuff
  if [[ -n "${ACF_KEY}" ]]; then
    sed -i "s^${ACF_KEY}^############^g" "${log_file}"
    # sed -i "/........../d" "${log_file}"
  fi

  # Filter out noise from scp deployment method
  if [[ "${DEPLOY}" == "SCP" ]]; then
    sed -i "/Sending file modes:/d" "${log_file}"
    sed -i "/Sink:/d" "${log_file}"
    sed -i "/debug1:/d" "${log_file}"
  fi

  # Filter PHP log output as configured by user
  if [[ "${NO_PHP}" == "TRUE" ]]; then
    grep -vE "(PHP |Notice:|Warning:|Strict Standards:)" "${log_file}" > "${post_file}"
    cat "${post_file}" > "${log_file}"
  fi

  # If logs should be terse, remove some more stuff
  if [[ "${TERSE}" == "TRUE" ]]; then
    sed -i -e '/Loading/d' \
      -e "/Enabled/d" \
      -e "/enabled/d" \
      -e "/Current user/d" \
      -e "/Current project/d" \
      -e "/Project WORK_PATH/d" \
      -e "/Locking process/d" \
      -e "/Running from/d" \
      -e "/lock/d" \
      -e "/Checking for deploy updates/d" \
      -e "/Log file is/d" \
      -e "/lock/d" \
      -e "/not found/d" \
      -e "/Checking for/d" \
      -e "/Continuing deploy/d" \
      "${log_file}"
  fi

  # Remove double line breaks
  sed -i '/^$/d' "${log_file}"
  
  # Replace empty lines where we want
  sed -i -e '/Checking servers/s/^/\n/' \
    -e '/Launching deployment/s/^/\n/' \
    -e '/Staging files/s/^/\n/' \
    -e '/Commit message/s/^/\n/' \
    -e '/Preparing repository/s/^/\n/' \
    -e '/Checking for updates/s/^/\n/' \
    -e '/The following updates/s/^/\n/' \
    -e '/installed plugins/s/^/\n/' \
    "${log_file}"

  # Is this a publish only?
  if [[ "${PUBLISH}" == "1" ]] && [[ -z "${notes}" ]]; then   
    notes="Published to production and marked as deployed"
  fi

  # Setup a couple of variables
  VIEWPORT="680"
  VIEWPORTPRE=$(expr ${VIEWPORT} - 80)

  # IF we're using HTML emails, let's get to work
  if [[ "${EMAIL_HTML}" == "TRUE" ]]; then
    [[ "${message_state}" != "DIGEST" ]] && build_html
    cat "${html_file}" > "${trash_file}"

    # If this is an approval email, strip out PHP
    if [[ "${message_state}" == "APPROVAL NEEDED" ]]; then 
      sed -i '/<?php/,/?>/d' "${trash_file}"
      sed -e "s^EMAIL BUTTONS: BEGIN^EMAIL BUTTONS: BEGIN //-->^g" -i "${trash_file}"
    fi

    # Strip out logs if necessary
    if [[ "${SHORT_EMAIL}" == "TRUE" ]]; then
      sed -i '/LOG: BEGIN/,/LOG: END/d' "${trash_file}"
    fi

    # Load the email into a variable
    htmlSendmail=$(<"${trash_file}")
  fi

  # Create HTML/PHP logs for viewing online
  if [[ "${REMOTE_LOG}" == "TRUE" ]]; then
    html_dir

    # For web logs, VIEWPORT should be 960
    VIEWPORT="960"
    VIEWPORTPRE=$(expr ${VIEWPORT} - 80)

    # Build the html email and details pages
    # build_html

    # Strip out the buttons that self-link
    sed -e "s^// BUTTON: BEGIN //-->^BUTTON HIDE^g" -i "${html_file}"
    post_log
  fi
}

function build_html() {
  LOGSUFFIX="html"
  
  # Build out the HTML
  if [[ "${message_state}" == "ERROR" ]]; then
    # Oh man, this is an error
    notes="${error_msg}"
    LOGTITLE="Deployment Error"
    # Create the header
    cat "${stir_path}/html/${HTML_TEMPLATE}/header.html" "${stir_path}/html/${HTML_TEMPLATE}/error.html" > "${html_file}"
  else
    # Does this project need to be approved before finalizing deployment?
    #if [[ "${REQUIRE_APPROVAL}" == "TRUE" ]] && [[ "${APPROVE}" != "1" ]] && [[ "${DIGEST}" != "1" ]] && [[ -f "${WORK_PATH}/${APP}/.queued" ]]; then
    if [[ "${REQUIRE_APPROVAL}" == "TRUE" ]] && [[ "${APPROVE}" != "1" ]] && [[ "${DIGEST}" != "1" ]]  && [[ "${REPORT}" != "1" ]]; then
      message_state="APPROVAL NEEDED"
      LOGTITLE="Approval Needed"
      LOGSUFFIX="php"
      # cat "${stir_path}/html/${HTML_TEMPLATE}/header.html" "${stir_path}/html/${HTML_TEMPLATE}/approve.html" > "${html_file}"
      cat "${stir_path}/html/${HTML_TEMPLATE}/approval.php" > "${html_file}"
    else
      if [[ "${AUTOMATE}" == "1" ]] && [[ "${APPROVE}" != "1" ]] && [[ "${UPD1}" == "1" ]] && [[ "${UPD2}" == "1" ]]; then
        message_state="NOTICE"
        LOGTITLE="Scheduled Update"
        notes="No updates available for deployment"
      else
        # Looks like we've got a normal successful deployment
        message_state="SUCCESS"
        # Is this a scheduled update?
        if [[ "${AUTOMATE}" == "1" ]]; then
          LOGTITLE="Scheduled Update"
        else
          LOGTITLE="Activity Log"
        fi
      fi
      if [[ "${DIGEST}" != "1" ]] && [[ "${REPORT}" != "1" ]]; then
        if [[ "${REPAIR}" == "1" ]] && [[ -z "${notes}" ]]; then
          notes="Merged and deployed codebase"
        fi
        cat "${stir_path}/html/${HTML_TEMPLATE}/header.html" "${stir_path}/html/${HTML_TEMPLATE}/success.html" > "${html_file}"
      fi
    fi
  fi

  # Create URL
  if [[ "${PUBLISH}" == "1" ]]; then
    LOGURL="${REMOTE_URL}/${APP}/${EPOCH}.${LOGSUFFIX}"
    REMOTEFILE="${EPOCH}.${LOGSUFFIX}"
  elif [[ "${SCAN}" == "1" ]]; then
    LOGURL="${REMOTE_URL}/${APP}/scan"
    REMOTEFILE="index.html"
  elif [[ "${message_state}" == "APPROVAL NEEDED" ]]; then
      LOGURL="${REMOTE_URL}/${APP}/APPROVAL-${EPOCH}.${LOGSUFFIX}"
      REMOTEFILE="APPROVAL-${EPOCH}.${LOGSUFFIX}"
  else
    if [[ "${message_state}" != "SUCCESS" ]] || [[ -z "${COMMITHASH}" ]]; then
      LOGURL="${REMOTE_URL}/${APP}/${message_state}-${EPOCH}.${LOGSUFFIX}"
      REMOTEFILE="${message_state}-${EPOCH}.${LOGSUFFIX}"
    else
      LOGURL="${REMOTE_URL}/${APP}/${COMMITHASH}.${LOGSUFFIX}"
      REMOTEFILE="${COMMITHASH}.${LOGSUFFIX}"
    fi
  fi

  # Insert the full deployment log_file & button it all up
  if [[ "${REPORT}" != "1" ]]; then
    cat "${log_file}" "${stir_path}/html/${HTML_TEMPLATE}/footer.html" >> "${html_file}"
    # There's probably a better place for this.
    process_html
  fi
}
