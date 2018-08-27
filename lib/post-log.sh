#!/usr/bin/env bash
#
# post-log.sh
#
###############################################################################
# Handles posting logs to localhost as well as remote hosts
###############################################################################
trace "Loading post functions"

# Initialize variables
read -r SCPPORT <<< ""
echo "${SCPPORT}" > /dev/null

# Remote log function; this really needs to be rewritten
function postLog() {
  if [[ "${REMOTELOG}" == "TRUE" ]]; then

    # Post to localhost by simply copying files
    if [[ "${LOCALHOSTPOST}" == "TRUE" ]] && [[ -n "${LOCALHOSTPATH}" ]] && [[ -f "${htmlFile}" ]]; then
      
      # Check that directory exists
      htmlDir

      # Post the file   
      if [[ -n "${REMOTEFILE}" ]] && [[ "${REPORT}" != "1" ]]; then #&& [[ -n "${COMMITHASH}" ]]; then
        cp "${htmlFile}" "${LOCALHOSTPATH}/${APP}/${REMOTEFILE}"
        chmod a+rw "${LOCALHOSTPATH}/${APP}/${REMOTEFILE}" &> /dev/null
      fi

      # Post the digest
      if [[ "${DIGEST}" == "1" ]]; then
        REMOTEFILE="digest-${EPOCH}.html"
        cp "${htmlFile}" "${LOCALHOSTPATH}/${APP}/${REMOTEFILE}"
        chmod a+rw "${LOCALHOSTPATH}/${APP}/${REMOTEFILE}" &> /dev/null
        DIGESTURL="${REMOTEURL}/${APP}/${REMOTEFILE}"
      fi

      # Post the report
      if [[ "${REPORT}" == "1" ]]; then
        REMOTEFILE="${EPOCH}.php"
        cp "${htmlFile}" "${LOCALHOSTPATH}/${APP}/report/${REMOTEFILE}"
        chmod a+rw "${LOCALHOSTPATH}/${APP}/report/${REMOTEFILE}" &> /dev/null
        REPORTURL="${REMOTEURL}/${APP}/report/${REMOTEFILE}"
      fi

      # Statistics
      if [[ "${PROJSTATS}" == "1" ]]; then
        [[ ! -d "${LOCALHOSTPATH}/${APP}" ]] && mkdir "${LOCALHOSTPATH}/${APP}"
        [[ ! -d "${LOCALHOSTPATH}/${APP}/stats" ]] && mkdir "${LOCALHOSTPATH}/${APP}/stats"
        cp -R "/tmp/stats" "${LOCALHOSTPATH}/${APP}"
        chmod -R a+rw "${deployPath}/html/${HTMLTEMPLATE}/stats" &> /dev/null
      fi

      # Remove logs older then X days
      if [[ -n "${EXPIRELOGS}" ]]; then
        is_integer "${EXPIRELOGS}"
        if [[ "${integer_check}" != "1" ]]; then
          find "${LOCALHOSTPATH}/${APP}"* -mtime +"${EXPIRELOGS}" -exec rm {} \; &> /dev/null
        fi
      fi
    fi

    # Send the files through SSH/SCP
    if [[ "${SCPPOST}" == "TRUE" ]] && [[ -f "${htmlFile}" ]]; then

      # if SCPPORT is empty, set it to 22
      #if [[ -z "${SCPPORT}" ]]; then
      #  SCPPORT="22"
      #fi

      # Setup up the proper command, depending on whether we're using key or password
      if [[ -n "${SCPPASS}" ]]; then
        TMP=$(<$SCPPASS)
        SCPPASS="${TMP}"
        SCPCMD="sshpass -p \"${SCPPASS}\" scp -o StrictHostKeyChecking=no -P \"${SCPPORT}\""
        SSHCMD="sshpass -p \"${SCPPASS}\" ssh -p \"${SCPPORT}\""
      else
        SCPCMD="scp -P \"${SCPPORT}\""
        SSHCMD="ssh -P \"${SCPPORT}\""
      fi

      # Loop through the various scenarios, make directories if needed
      eval "${SSHCMD}" "${SCPUSER}"@"${SCPHOST}" "mkdir -p ${SCPHOSTPATH}/${APP}"

      if [[ "${DIGEST}" == "1" ]]; then
        REMOTEFILE="digest-${EPOCH}.html"
        DIGESTURL="${REMOTEURL}/${APP}/${REMOTEFILE}"
        #eval "${SSHCMD}" "${SCPUSER}"@"${SCPHOST}" "mkdir -p ${SCPHOSTPATH}/${APP}/avatar"
        #eval "${SCPCMD} -r" "/tmp/avatar/" "${SCPUSER}"@"${SCPHOST}":"${SCPHOSTPATH}/${APP}"
        # Clean up your mess
        #if [[ -d "/tmp/avatar" ]]; then
        #  rm -R "/tmp/avatar"
        #fi
      fi

      if [[ "${PROJSTATS}" == "1" || "${DIGEST}" == "1" ]]; then
        eval "${SSHCMD}" "${SCPUSER}"@"${SCPHOST}" "mkdir -p ${SCPHOSTPATH}/${APP}/stats"
        eval "${SCPCMD} -r" "/tmp/stats/" "${SCPUSER}"@"${SCPHOST}":"${SCPHOSTPATH}/${APP}"
        eval "${SSHCMD}" "${SCPUSER}"@"${SCPHOST}" "mkdir -p ${SCPHOSTPATH}/${APP}/avatar"
        eval "${SCPCMD} -r" "/tmp/avatar/" "${SCPUSER}"@"${SCPHOST}":"${SCPHOSTPATH}/${APP}"
        # Clean up your mess
        if [[ -d "/tmp/stats" ]]; then
          rm -R "/tmp/stats"
        fi
        if [[ -d "/tmp/avatar" ]]; then
          rm -R "/tmp/avatar"
        fi
      fi

      if [[ "${SCAN}" == "1" ]]; then
        trace "Sending /scan"
        eval "${SSHCMD}" "${SCPUSER}"@"${SCPHOST}" "mkdir -p ${SCPHOSTPATH}/${APP}/scan"
        eval "${SCPCMD} -r" "${scan_html}" "${SCPUSER}"@"${SCPHOST}":"${SCPHOSTPATH}/${APP}/scan/index.html"
        # This stuff is for the new dashboard method
        eval "${SCPCMD} -r" "/tmp/stats/" "${SCPUSER}"@"${SCPHOST}":"${SCPHOSTPATH}/${APP}"
        # Clean up your mess
        #if [[ -d "/tmp/stats" ]]; then
        #  rm -R "/tmp/stats"
        #fi
      fi

      if [[ "${REPORT}" == "1" ]]; then
        REMOTEFILE="${CURYR}-${CURMTH}.php"
        REPORTURL="${REMOTEURL}/${APP}/report/${REMOTEFILE}"
        trace "Running \"${SSHCMD}\" \"${SCPUSER}\"@\"${SCPHOST}\" \"mkdir -p ${SCPHOSTPATH}/${APP}/report\""
        eval "${SSHCMD}" "${SCPUSER}"@"${SCPHOST}" "mkdir -p ${SCPHOSTPATH}/${APP}/report"
        eval "${SSHCMD}" "${SCPUSER}"@"${SCPHOST}" "mkdir -p ${SCPHOSTPATH}/${APP}/report/css"
        eval "${SCPCMD} -r" "${deployPath}/html/${HTMLTEMPLATE}/report/css" "${SCPUSER}"@"${SCPHOST}":"${SCPHOSTPATH}/${APP}/report"
        eval "${SSHCMD}" "${SCPUSER}"@"${SCPHOST}" "mkdir -p ${SCPHOSTPATH}/${APP}/report/js"
        eval "${SCPCMD} -r" "${deployPath}/html/${HTMLTEMPLATE}/report/js" "${SCPUSER}"@"${SCPHOST}":"${SCPHOSTPATH}/${APP}/report"
        eval "${SCPCMD}" "${htmlFile}" "${SCPUSER}"@"${SCPHOST}":"${SCPHOSTPATH}/${APP}/report/${REMOTEFILE}"
      fi

      # Send over the logs and set permissions
      if [[ "${REPORT}" != "1" ]] && [[ "${PROJSTATS}" != "1" ]]; then 
        eval "${SCPCMD}" "${htmlFile}" "${SCPUSER}"@"${SCPHOST}":"${SCPHOSTPATH}/${APP}/${REMOTEFILE}" &> /dev/null
      fi

      # Remove logs older then X days
      if [[ -n "${EXPIRELOGS}" ]]; then
        is_integer "${EXPIRELOGS}"
        if [[ "${integer_check}" != "1" ]]; then
          eval "${SSHCMD}" "${SCPUSER}"@"${SCPHOST}" "'find ${SCPHOSTPATH}/${APP}* -mtime +${EXPIRELOGS} -exec rm {} \;' &> /dev/null"
        fi
      fi

      # Set permissions
      eval "${SSHCMD}" "${SCPUSER}"@"${SCPHOST}" "chmod -R 755 ${SCPHOSTPATH}/${APP}/"
    fi
  fi
}

function htmlDir() {
  # Yet another if/then to cover my ass. What a mess!
  if [[ "${LOCALHOSTPOST}" == "TRUE" ]] && [[ -n "${LOCALHOSTPATH}" ]]; then

    if [[ ! -d "${LOCALHOSTPATH}/${APP}" ]]; then
      mkdir "${LOCALHOSTPATH}/${APP}"
    fi

    if [[ ! -d "${LOCALHOSTPATH}/${APP}/avatar" ]]; then
      mkdir "${LOCALHOSTPATH}/${APP}/avatar"
    fi

    if [[ "${message_state}" == "REPORT" ]]; then 
      if [[ ! -d "${LOCALHOSTPATH}/${APP}/report" ]]; then
        mkdir "${LOCALHOSTPATH}/${APP}/report"; error_check
        mkdir "${LOCALHOSTPATH}/${APP}/report/css"; error_check
        mkdir "${LOCALHOSTPATH}/${APP}/report/js"; error_check
      fi
        cp -R "${deployPath}/html/${HTMLTEMPLATE}/report/css" "${LOCALHOSTPATH}/${APP}/report"; error_check
        cp -R "${deployPath}/html/${HTMLTEMPLATE}/report/js" "${LOCALHOSTPATH}/${APP}/report"; error_check
    fi
  fi
}
