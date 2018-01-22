#!/usr/bin/env bash
#
# log-handling.sh
#
###############################################################################
# Handles parsing and creating logs
###############################################################################
trace "Loading log handling"

function makeLog() {
  # Clean up stuff that is most likely there
  sed -i -e '/git reset HEAD/d' \
    -e '/Checking out files:/d' \
    -e '/Unpacking objects:/d' \
    "${logFile}"

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
    "${logFile}"

  # Clean up mina's goobers
  if [[ "${DEPLOY}" == *"mina"* ]]; then
    sed -i -e '/0m Creating a temporary build path/c\Creating a temporary build path' \
      -e '/0m Fetching new git commits/c\Fetching new git commits' \
      -e '/0m Using git branch ${PRODUCTION}/c\Using git branch ${PRODUCTION}' \
      -e '/0m Using this git commit/c\Using this git commit' \
      -e '/0m Cleaning up old releases/c\Cleaning up old releases' \
      -e '/0m Build finished/c\Build finished' \
      "${logFile}"

    # Totally remove these lines
    sed -i "/----->/d" "${logFile}"
    sed -i "/0m/d" "${logFile}"
    sed -i "/Resolving deltas:/d" "${logFile}"
    sed -i "/remote:/d" "${logFile}"
    sed -i "/Receiving objects:/d" "${logFile}"
    sed -i "/Resolving deltas:/d" "${logFile}"

    # If incognito, remove this stuff for privacy
    if [[ "${INCOGNITO}" == "TRUE" ]]; then
      sed -i "/Using cached file/d" "${logFile}"
    fi
  fi

  # Filter out ACF license key & wget stuff
  if [[ -n "${ACFKEY}" ]]; then
    sed -i "s^${ACFKEY}^############^g" "${logFile}"
    # sed -i "/........../d" "${logFile}"
  fi

  # Filter raw log output as configured by user
  if [[ "${NOPHP}" == "TRUE" ]]; then
    grep -vE "(PHP |Notice:|Warning:|Strict Standards:)" "${logFile}" > "${postFile}"
    cat "${postFile}" > "${logFile}"
  fi

  # Is this a publish only?
  if [[ "${PUBLISH}" == "1" ]] && [[ -z "${notes}" ]]; then   
    notes="Published to production and marked as deployed"
  fi

  # Setup a couple of variables
  VIEWPORT="680"
  VIEWPORTPRE=$(expr ${VIEWPORT} - 80)

  # IF we're using HTML emails, let's get to work
  if [[ "${EMAILHTML}" == "TRUE" ]]; then
    [[ "${message_state}" != "DIGEST" ]] && build_html
    cat "${htmlFile}" > "${trshFile}"

    # If this is an approval email, strip out PHP
    if [[ "${message_state}" == "APPROVAL NEEDED" ]]; then 
      sed -i '/<?php/,/?>/d' "${trshFile}"
      sed -e "s^EMAIL BUTTONS: BEGIN^EMAIL BUTTONS: BEGIN //-->^g" -i "${trshFile}"
    fi

    # Strip out logs if necessary
    if [[ "${SHORTEMAIL}" == "TRUE" ]]; then
      sed -i '/LOG: BEGIN/,/LOG: END/d' "${trshFile}"
    fi

    # Load the email into a variable
    htmlSendmail=$(<"${trshFile}")
  fi

  # Create HTML/PHP logs for viewing online
  if [[ "${REMOTELOG}" == "TRUE" ]]; then
    htmlDir

    # For web logs, VIEWPORT should be 960
    VIEWPORT="960"
    VIEWPORTPRE=$(expr ${VIEWPORT} - 80)

    # Build the html email and details pages
    # build_html

    # Strip out the buttons that self-link
    sed -e "s^// BUTTON: BEGIN //-->^BUTTON HIDE^g" -i "${htmlFile}"
    postLog
  fi
}

function build_html() {
  # Build out the HTML
  LOGSUFFIX="html"
  if [[ "${message_state}" == "ERROR" ]]; then
    # Oh man, this is an error
    notes="${error_msg}"
    LOGTITLE="Deployment Error"
    # Create the header
    cat "${deployPath}/html/${HTMLTEMPLATE}/header.html" "${deployPath}/html/${HTMLTEMPLATE}/error.html" > "${htmlFile}"
  else
    # Does this project need to be approved before finalizing deployment?
    #if [[ "${REQUIREAPPROVAL}" == "TRUE" ]] && [[ "${APPROVE}" != "1" ]] && [[ "${DIGEST}" != "1" ]] && [[ -f "${WORKPATH}/${APP}/.queued" ]]; then
    if [[ "${REQUIREAPPROVAL}" == "TRUE" ]] && [[ "${APPROVE}" != "1" ]] && [[ "${DIGEST}" != "1" ]]  && [[ "${REPORT}" != "1" ]]; then
      message_state="APPROVAL NEEDED"
      LOGTITLE="Approval Needed"
      LOGSUFFIX="php"
      # cat "${deployPath}/html/${HTMLTEMPLATE}/header.html" "${deployPath}/html/${HTMLTEMPLATE}/approve.html" > "${htmlFile}"
      cat "${deployPath}/html/${HTMLTEMPLATE}/approval.php" > "${htmlFile}"
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
          LOGTITLE="Deployment Log"
        fi
      fi
      if [[ "${DIGEST}" != "1" ]] && [[ "${REPORT}" != "1" ]]; then
        if [[ "${REPAIR}" == "1" ]] && [[ -z "${notes}" ]]; then
          notes="Repaired and deployed codebase"
        fi
        cat "${deployPath}/html/${HTMLTEMPLATE}/header.html" "${deployPath}/html/${HTMLTEMPLATE}/success.html" > "${htmlFile}"
      fi
    fi
  fi

  # Create URL
  if [[ "${PUBLISH}" == "1" ]]; then
    LOGURL="${REMOTEURL}/${APP}/${EPOCH}.${LOGSUFFIX}"
    REMOTEFILE="${EPOCH}.${LOGSUFFIX}"
  else
    if [[ "${message_state}" == "APPROVAL NEEDED" ]]; then
      LOGURL="${REMOTEURL}/${APP}/APPROVAL-${EPOCH}.${LOGSUFFIX}"
      REMOTEFILE="APPROVAL-${EPOCH}.${LOGSUFFIX}"
    else
      if [[ "${message_state}" != "SUCCESS" ]] || [[ -z "${COMMITHASH}" ]]; then
        LOGURL="${REMOTEURL}/${APP}/${message_state}-${EPOCH}.${LOGSUFFIX}"
        REMOTEFILE="${message_state}-${EPOCH}.${LOGSUFFIX}"
      else
        LOGURL="${REMOTEURL}/${APP}/${COMMITHASH}.${LOGSUFFIX}"
        REMOTEFILE="${COMMITHASH}.${LOGSUFFIX}"
      fi
    fi
  fi

  # Insert the full deployment logfile & button it all up
  if [[ "${REPORT}" != "1" ]]; then
    cat "${logFile}" "${deployPath}/html/${HTMLTEMPLATE}/footer.html" >> "${htmlFile}"
    # There's probably a better place for this.
    process_html
  fi
}
