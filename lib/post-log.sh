#!/usr/bin/env bash
#
# post-log.sh
#
###############################################################################
# Handles posting logs to localhost as well as remote hosts
###############################################################################

# Initialize variables
var=(SCPPORT)
init_loop

# Remote log function; this really needs to be rewritten
function post_log() {
  if [[ "${REMOTELOG}" == "TRUE" ]]; then

    # Post to localhost by simply copying files
    if [[ "${LOCALHOSTPOST}" == "TRUE" ]] && [[ -n "${LOCALHOSTPATH}" ]] && [[ -f "${htmlFile}" ]]; then
      
      # Check that directory exists
      html_dir

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
        cp -R "${statDir}" "${LOCALHOSTPATH}/${APP}"
        chmod -R a+rw "${stir_path}/html/${HTMLTEMPLATE}/stats" &> /dev/null
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

      # Setup up the proper command, depending on whether we're using key or password
      if [[ -n "${SCPPASS}" ]] && [[ -n "${sshpass_cmd}" ]]; then
        TMP=$(<$SCPPASS)
        SCPPASS="${TMP}"
        SCPCMD="${sshpass_cmd} -p \"${SCPPASS}\" scp -o StrictHostKeyChecking=no -P \"${SCPPORT}\""
        SSHCMD="${sshpass_cmd} -p \"${SCPPASS}\" ssh -p \"${SCPPORT}\""
      elif [[ -n "${scp_cmd}" ]]; then
        SCPCMD="${scp_cmd} -P \"${SCPPORT}\""
        SSHCMD="${ssh_cmd} -p \"${SCPPORT}\""
      else
        return
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

      if [[ "${PROJSTATS}" == "1" || "${DIGEST}" == "1" && -f "${statDir}/*" ]]; then
        eval "${SSHCMD}" "${SCPUSER}"@"${SCPHOST}" "mkdir -p ${SCPHOSTPATH}/${APP}/stats"
        eval "${SCPCMD} -r" "${statDir}/*" "${SCPUSER}"@"${SCPHOST}":"${SCPHOSTPATH}/${APP}/stats/"
        eval "${SSHCMD}" "${SCPUSER}"@"${SCPHOST}" "mkdir -p ${SCPHOSTPATH}/${APP}/avatar"
        eval "${SCPCMD} -r" "${avatarDir}/*" "${SCPUSER}"@"${SCPHOST}":"${SCPHOSTPATH}/${APP}/avatar/"
        # Clean up your mess
        #if [[ -d "${statDir}" ]]; then
        #  rm -R "${statDir}"
        #fi
        if [[ -d "${avatarDir}" ]]; then
          rm -R "${avatarDir}"
        fi
      fi

      if [[ "${SCAN}" == "1" ]]; then
        trace "Sending /scan"
        eval "${SSHCMD}" "${SCPUSER}"@"${SCPHOST}" "mkdir -p ${SCPHOSTPATH}/${APP}/scan"
        eval "${SCPCMD} -r" "${scan_html}" "${SCPUSER}"@"${SCPHOST}":"${SCPHOSTPATH}/${APP}/scan/index.html"
        # This stuff is for the new dashboard method
        eval "${SCPCMD} -r" "${statDir}/*" "${SCPUSER}"@"${SCPHOST}":"${SCPHOSTPATH}/${APP}/stats/"
        # Clean up your mess
        #if [[ -d "${statDir}" ]]; then
        #  rm -R "${statDir}"
        #fi
      fi

      if [[ "${REPORT}" == "1" ]]; then
        REMOTEFILE="${current_year}-${current_month}.php"
        REPORTURL="${REMOTEURL}/${APP}/report/${REMOTEFILE}"
        trace "Running \"${SSHCMD}\" \"${SCPUSER}\"@\"${SCPHOST}\" \"mkdir -p ${SCPHOSTPATH}/${APP}/report\""
        eval "${SSHCMD}" "${SCPUSER}"@"${SCPHOST}" "mkdir -p ${SCPHOSTPATH}/${APP}/report"
        eval "${SSHCMD}" "${SCPUSER}"@"${SCPHOST}" "mkdir -p ${SCPHOSTPATH}/${APP}/report/css"
        eval "${SCPCMD} -r" "${stir_path}/html/${HTMLTEMPLATE}/report/css" "${SCPUSER}"@"${SCPHOST}":"${SCPHOSTPATH}/${APP}/report"
        eval "${SSHCMD}" "${SCPUSER}"@"${SCPHOST}" "mkdir -p ${SCPHOSTPATH}/${APP}/report/js"
        eval "${SCPCMD} -r" "${stir_path}/html/${HTMLTEMPLATE}/report/js" "${SCPUSER}"@"${SCPHOST}":"${SCPHOSTPATH}/${APP}/report"
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

function html_dir() {
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
        cp -R "${stir_path}/html/${HTMLTEMPLATE}/report/css" "${LOCALHOSTPATH}/${APP}/report"; error_check
        cp -R "${stir_path}/html/${HTMLTEMPLATE}/report/js" "${LOCALHOSTPATH}/${APP}/report"; error_check
    fi
  fi
}
