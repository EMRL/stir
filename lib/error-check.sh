#!/usr/bin/env bash
#
# error_check()
#
###############################################################################
# Handles various exit code checking
###############################################################################

# Initialize variables
var=(error_detail last_command)
init_loop

# Try to get exit/error code, with a hard stop on fail
function error_check() {
  EXITCODE=$?; 
  if [[ "${EXITCODE}" != 0 ]]; then
    if [[ -z "${error_detail}" ]]; then
      error_detail="Operation fault"
    fi
    warning "${error_detail} (Error ${EXITCODE})"
    error_msg="${error_detail} (Error ${EXITCODE})"
    error_exit
  else
    error_detail=""
  fi
}

# I'm not sure why this is here, figure it out!
# Try to get exit/error code, with a hard stop on fail
function error_status() {
  EXITCODE=$?; 
  if [[ "${EXITCODE}" != 0 ]]; then 
    error_msg="WARNING: Error code ${EXITCODE}"
    trace "${error_msg}"
  fi
}

function deploy_check() {
  if [[ "${DEPLOY}" == *"mina"* ]]; then # && [[ "${DEPLOY}" != *"bundle"* ]]; then
    DEPLOYTEST="mina --simulate deploy"
    # Get variables organized
    if [[ -f "${WORK_PATH}/${APP}/${CONFIG_DIR}/deploy.rb" ]]; then
      grep -n -w "set :user" "${WORK_PATH}/${APP}/${CONFIG_DIR}"/deploy.rb > "${trash_file}"
      MINAUSER=$(awk -F\' '{print $2,$4}' ${trash_file})
      echo -n "${MINAUSER}" > "${stat_file}"
      echo -n "@" >> ${stat_file}
      grep -n -w "set :domain" "${WORK_PATH}/${APP}/${CONFIG_DIR}"/deploy.rb > "${trash_file}"
      MINADOMAIN=$(awk -F\' '{print $2,$4}' ${trash_file})
      echo -n "${MINADOMAIN}" >> "${stat_file}"
      SSHTARGET=$(sed -r 's/\s+//g' ${stat_file})
      # SSH check
      if [[ "${INCOGNITO}" != "TRUE" ]]; then
        trace "Testing connection for ${SSHTARGET}"
      else
        trace "Testing connection"
      fi
      SSHSTATUS=$(ssh -o BatchMode=yes -o ConnectTimeout=10 ${SSHTARGET} echo ok 2>&1)

    elif [[ -f "${WORK_PATH}/${APP}/.deploy.yml" ]]; then
      DEPLOYTEST="bundle exec mina --simulate deploy -f Minafile"
      grep -n -w "user:" "${WORK_PATH}/${APP}"/.deploy.yml > "${trash_file}"
      
      if grep -aq "'" "${trash_file}"; then
        MINAUSER=$(awk -F\' '{print $2,$4}' ${trash_file}) # Single quote method
      else
        MINAUSER=$(awk 'NF>1{print $NF}' ${trash_file})
      fi

      echo -n "${MINAUSER}" > "${stat_file}"
      echo -n "@" >> ${stat_file}
      grep -n -w "domain:" "${WORK_PATH}/${APP}"/.deploy.yml > "${trash_file}"

      if grep -aq "'" "${trash_file}"; then
        MINADOMAIN=$(awk -F\' '{print $2,$4}' ${trash_file}) # Single quote method
      else
        MINADOMAIN=$(awk 'NF>1{print $NF}' ${trash_file})
      fi

      echo -n "${MINADOMAIN}" >> "${stat_file}"
      SSHTARGET=$(sed -r 's/\s+//g' ${stat_file})  
      # SSH check
      if [[ "${INCOGNITO}" != "TRUE" ]]; then
        trace "Testing connection for ${SSHTARGET}"
      else
        trace "Testing connection"
      fi
      SSHSTATUS=$(ssh -o BatchMode=yes -o ConnectTimeout=10 ${SSHTARGET} echo ok 2>&1)
    fi

    if [[ "${SSHSTATUS}" == *"ok"* ]] ; then
      # Continue deploying
      trace "${SSHTARGET}: OK"
    elif [[ "${SSHSTATUS}" == *"Permission denied"* ]] ; then
      # Not authorized, no key etc.
      error "Connection refused for ${SSHTARGET}"
    else
      if [[ "${AUTOMATE}" == "1" ]]; then
        error "Connection for ${SSHTARGET} not established, an unknown error occurred."
      else
        warning "Connection for ${SSHTARGET} not established, an unknown error occurred."   
        # Ok now offer to re-run mina in verbose mode if someone is at the console
        # If FORCE=1 then simply exit
        if [[ "${FORCE}" == "1" ]] || yesno --default yes "Retry ${DEPLOY} in verbose mode? [Y/n] "; then
          eval "ssh ${SSHTARGET}" | tee --append "${log_file}"
          # eval "${DEPLOY}" | tee --append "${log_file}"
        else
          error "Connection for ${SSHTARGET} not established, an unknown error occurred."
        fi
      fi
    fi

    # Try to --simulate the command
    trace "Testing deployment command: ${DEPLOYTEST}"

    # When using bundle, make sure it exists
    if [[ "${DEPLOYTEST}" == *"bundle"* ]]; then
      eval "bundle check" &>> /dev/null
      EXITCODE=$?;
      if [[ "${EXITCODE}" != 0 ]]; then
        warning "Could not locate Gemfile or .bundle/ directory, installing..." 
        eval "bundle install" | tee --append "${log_file}"
        eval "bundle check" &>> /dev/null
        EXITCODE=$?;
        if [[ "${EXITCODE}" != 0 ]]; then
          error "Problem with bundle gem (Error ${EXITCODE})"
        fi
      fi
    fi

    eval "${DEPLOYTEST}" &>> /dev/null
    EXITCODE=$?; 
    if [[ "${EXITCODE}" != 0 ]]; then 
      warning "Deployment exited due to a configuration problem (Error ${EXITCODE})"
      error_msg="Deployment exited due to a configuration problem (Error ${EXITCODE})"
      error_exit
    fi
    trace "OK"
  fi
}
