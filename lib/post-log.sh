#!/usr/bin/env bash
#
# post-log.sh
#
###############################################################################
# Handles posting logs to localhost as well as remote hosts
###############################################################################

# Initialize variables
var=(SCP_PORT)
init_loop

# Remote log function; this really needs to be rewritten
function post_log() {
  if [[ "${REMOTE_LOG}" == "TRUE" ]]; then

    # Post to localhost by simply copying files
    if [[ "${POST_TO_LOCAL_HOST}" == "TRUE" ]] && [[ -n "${LOCAL_HOST_PATH}" ]] && [[ -f "${html_file}" ]]; then
      
      # Check that directory exists
      html_dir

      # Post the file   
      if [[ -n "${REMOTEFILE}" ]] && [[ "${REPORT}" != "1" ]]; then #&& [[ -n "${COMMITHASH}" ]]; then
        cp "${html_file}" "${LOCAL_HOST_PATH}/${APP}/${REMOTEFILE}"
        chmod a+rw "${LOCAL_HOST_PATH}/${APP}/${REMOTEFILE}" &> /dev/null
      fi

      # Post the digest
      if [[ "${DIGEST}" == "1" ]]; then
        REMOTEFILE="digest-${EPOCH}.html"
        cp "${html_file}" "${LOCAL_HOST_PATH}/${APP}/${REMOTEFILE}"
        chmod a+rw "${LOCAL_HOST_PATH}/${APP}/${REMOTEFILE}" &> /dev/null
        DIGESTURL="${REMOTE_URL}/${APP}/${REMOTEFILE}"
      fi

      # Post the report
      if [[ "${REPORT}" == "1" ]]; then
        REMOTEFILE="${current_year}-${current_month}.php"
        cp "${html_file}" "${LOCAL_HOST_PATH}/${APP}/report/${REMOTEFILE}"
        chmod a+rw "${LOCAL_HOST_PATH}/${APP}/report/${REMOTEFILE}" &> /dev/null
        REPORTURL="${REMOTE_URL}/${APP}/report/${REMOTEFILE}"
      fi

      # Statistics
      if [[ "${PROJSTATS}" == "1" ]]; then
        [[ ! -d "${LOCAL_HOST_PATH}/${APP}" ]] && mkdir "${LOCAL_HOST_PATH}/${APP}"
        [[ ! -d "${LOCAL_HOST_PATH}/${APP}/stats" ]] && mkdir "${LOCAL_HOST_PATH}/${APP}/stats"
        cp -R "${stat_dir}" "${LOCAL_HOST_PATH}/${APP}"
        chmod -R a+rw "${stir_path}/html/${HTML_TEMPLATE}/stats" &> /dev/null
      fi

      # Remove logs older then X days
      if [[ -n "${EXPIRE_LOGS}" ]]; then
        is_integer "${EXPIRE_LOGS}"
        if [[ "${integer_check}" != "1" ]]; then
          find "${LOCAL_HOST_PATH}/${APP}"* -mtime +"${EXPIRE_LOGS}" -exec rm {} \; &> /dev/null
        fi
      fi
    fi

    # Send the files through SSH/SCP
    if [[ "${SCP_POST}" == "TRUE" ]] && [[ -f "${html_file}" ]]; then

      # Setup up the proper command, depending on whether we're using key or password
      if [[ -n "${SCP_PASS}" ]] && [[ -n "${sshpass_cmd}" ]]; then
        TMP=$(<$SCP_PASS)
        SCP_PASS="${TMP}"
        SCPCMD="${sshpass_cmd} -p \"${SCP_PASS}\" scp -o StrictHostKeyChecking=no -P \"${SCP_PORT}\""
        SSHCMD="${sshpass_cmd} -p \"${SCP_PASS}\" ssh -p \"${SCP_PORT}\""
      elif [[ -n "${scp_cmd}" ]]; then
        SCPCMD="${scp_cmd} -P \"${SCP_PORT}\""
        SSHCMD="${ssh_cmd} -p \"${SCP_PORT}\""
      else
        return
      fi

      # Loop through the various scenarios, make directories if needed
      eval "${SSHCMD}" "${SCP_USER}"@"${SCP_HOST}" "mkdir -p ${SCP_HOST_PATH}/${APP}"

      if [[ "${DIGEST}" == "1" ]]; then
        REMOTEFILE="digest-${EPOCH}.html"
        DIGESTURL="${REMOTE_URL}/${APP}/${REMOTEFILE}"
      fi

      if [[ "${PROJSTATS}" == "1" || "${DIGEST}" == "1" && -f "${stat_dir}/*" ]]; then
        eval "${SSHCMD}" "${SCP_USER}"@"${SCP_HOST}" "mkdir -p ${SCP_HOST_PATH}/${APP}/stats"
        eval "${SCPCMD} -r" "${stat_dir}/*" "${SCP_USER}"@"${SCP_HOST}":"${SCP_HOST_PATH}/${APP}/stats/"
        eval "${SSHCMD}" "${SCP_USER}"@"${SCP_HOST}" "mkdir -p ${SCP_HOST_PATH}/${APP}/avatar"
        eval "${SCPCMD} -r" "${avatar_dir}/*" "${SCP_USER}"@"${SCP_HOST}":"${SCP_HOST_PATH}/${APP}/avatar/"
        if [[ -d "${avatar_dir}" ]]; then
          rm -R "${avatar_dir}"
        fi
      fi

      if [[ "${SCAN}" == "1" ]]; then
        trace "Sending /scan"
        eval "${SSHCMD}" "${SCP_USER}"@"${SCP_HOST}" "mkdir -p ${SCP_HOST_PATH}/${APP}/scan"
        eval "${SCPCMD} -r" "${scan_html}" "${SCP_USER}"@"${SCP_HOST}":"${SCP_HOST_PATH}/${APP}/scan/index.html"
        # This stuff is for the new dashboard method
        eval "${SCPCMD} -r" "${stat_dir}/*" "${SCP_USER}"@"${SCP_HOST}":"${SCP_HOST_PATH}/${APP}/stats/"
      fi

      if [[ "${REPORT}" == "1" ]]; then
        REMOTEFILE="${current_year}-${current_month}.php"
        eval "${SSHCMD}" "${SCP_USER}"@"${SCP_HOST}" "mkdir -p ${SCP_HOST_PATH}/${APP}/report"
        eval "${SSHCMD}" "${SCP_USER}"@"${SCP_HOST}" "mkdir -p ${SCP_HOST_PATH}/${APP}/report/css"
        eval "${SCPCMD} -r" "${stir_path}/html/${HTML_TEMPLATE}/report/css" "${SCP_USER}"@"${SCP_HOST}":"${SCP_HOST_PATH}/${APP}/report"
        eval "${SSHCMD}" "${SCP_USER}"@"${SCP_HOST}" "mkdir -p ${SCP_HOST_PATH}/${APP}/report/js"
        eval "${SCPCMD} -r" "${stir_path}/html/${HTML_TEMPLATE}/report/js" "${SCP_USER}"@"${SCP_HOST}":"${SCP_HOST_PATH}/${APP}/report"
        eval "${SCPCMD}" "${html_file}" "${SCP_USER}"@"${SCP_HOST}":"${SCP_HOST_PATH}/${APP}/report/${REMOTEFILE}"
      fi

      # Send over the logs and set permissions
      if [[ "${REPORT}" != "1" ]] && [[ "${PROJSTATS}" != "1" ]]; then 
        eval "${SCPCMD}" "${html_file}" "${SCP_USER}"@"${SCP_HOST}":"${SCP_HOST_PATH}/${APP}/${REMOTEFILE}" &> /dev/null
      fi

      # Remove logs older then X days
      if [[ -n "${EXPIRE_LOGS}" ]]; then
        is_integer "${EXPIRE_LOGS}"
        if [[ "${integer_check}" != "1" ]]; then
          eval "${SSHCMD}" "${SCP_USER}"@"${SCP_HOST}" "'find ${SCP_HOST_PATH}/${APP}* -mtime +${EXPIRE_LOGS} -exec rm {} \;' &> /dev/null"
        fi
      fi

      # Set permissions
      eval "${SSHCMD}" "${SCP_USER}"@"${SCP_HOST}" "chmod -R 755 ${SCP_HOST_PATH}/${APP}/"
    fi
  fi
}

function html_dir() {
  # Yet another if/then to cover my ass. What a mess!
  if [[ "${POST_TO_LOCAL_HOST}" == "TRUE" ]] && [[ -n "${LOCAL_HOST_PATH}" ]]; then

    if [[ ! -d "${LOCAL_HOST_PATH}/${APP}" ]]; then
      mkdir "${LOCAL_HOST_PATH}/${APP}"
    fi

    if [[ ! -d "${LOCAL_HOST_PATH}/${APP}/avatar" ]]; then
      mkdir "${LOCAL_HOST_PATH}/${APP}/avatar"
    fi

    if [[ "${message_state}" == "REPORT" ]]; then 
      if [[ ! -d "${LOCAL_HOST_PATH}/${APP}/report" ]]; then
        mkdir "${LOCAL_HOST_PATH}/${APP}/report"; error_check
        mkdir "${LOCAL_HOST_PATH}/${APP}/report/css"; error_check
        mkdir "${LOCAL_HOST_PATH}/${APP}/report/js"; error_check
      fi
        cp -R "${stir_path}/html/${HTML_TEMPLATE}/report/css" "${LOCAL_HOST_PATH}/${APP}/report"; error_check
        cp -R "${stir_path}/html/${HTML_TEMPLATE}/report/js" "${LOCAL_HOST_PATH}/${APP}/report"; error_check
    fi
  fi
}
