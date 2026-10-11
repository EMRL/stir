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
error_check() {
  EXIT_CODE=$?; 
  if [[ "${EXIT_CODE}" != 0 ]]; then
    if [[ -z "${error_detail}" ]]; then
      error_detail="Operation fault"
    fi
    warning "${error_detail} (Error ${EXIT_CODE})"
    error_msg="${error_detail} (Error ${EXIT_CODE})"
    error_exit
  else
    error_detail=""
  fi
}

# I'm not sure why this is here, figure it out!
# Try to get exit/error code, with a hard stop on fail
error_status() {
  EXIT_CODE=$?; 
  if [[ "${EXIT_CODE}" != 0 ]]; then 
    error_msg="WARNING: Error code ${EXIT_CODE}"
    trace "${error_msg}"
  fi
}

deploy_check() {
  if [[ "${DEPLOY}" == *"mina"* ]]; then # && [[ "${DEPLOY}" != *"bundle"* ]]; then
    DEPLOY_TEST="mina --simulate deploy"
    # Get variables organized
    if [[ -f "${WORK_PATH}/${APP}/${CONFIG_DIR}/deploy.rb" ]]; then
      grep -n -w "set :user" "${WORK_PATH}/${APP}/${CONFIG_DIR}"/deploy.rb > "${trash_file}"
      MINA_USER=$(awk -F\' '{print $2,$4}' ${trash_file})
      echo -n "${MINA_USER}" > "${stat_file}"
      echo -n "@" >> ${stat_file}
      grep -n -w "set :domain" "${WORK_PATH}/${APP}/${CONFIG_DIR}"/deploy.rb > "${trash_file}"
      MINA_DOMAIN=$(awk -F\' '{print $2,$4}' ${trash_file})
      echo -n "${MINA_DOMAIN}" >> "${stat_file}"
      SSH_TARGET=$(sed -r 's/\s+//g' ${stat_file})
      # SSH check
      if [[ "${INCOGNITO}" != "TRUE" ]]; then
        trace "Testing connection for ${SSH_TARGET}"
      else
        trace "Testing connection"
      fi
      SSH_STATUS=$(ssh -o BatchMode=yes -o ConnectTimeout=10 ${SSH_TARGET} echo ok 2>&1)

    elif [[ -f "${WORK_PATH}/${APP}/.deploy.yml" ]]; then
      DEPLOY_TEST="bundle exec mina --simulate deploy -f Minafile"
      grep -n -w "user:" "${WORK_PATH}/${APP}"/.deploy.yml > "${trash_file}"
      
      if grep -aq "'" "${trash_file}"; then
        MINA_USER=$(awk -F\' '{print $2,$4}' ${trash_file}) # Single quote method
      else
        MINA_USER=$(awk 'NF>1{print $NF}' ${trash_file})
      fi

      echo -n "${MINA_USER}" > "${stat_file}"
      echo -n "@" >> ${stat_file}
      grep -n -w "domain:" "${WORK_PATH}/${APP}"/.deploy.yml > "${trash_file}"

      if grep -aq "'" "${trash_file}"; then
        MINA_DOMAIN=$(awk -F\' '{print $2,$4}' ${trash_file}) # Single quote method
      else
        MINA_DOMAIN=$(awk 'NF>1{print $NF}' ${trash_file})
      fi

      echo -n "${MINA_DOMAIN}" >> "${stat_file}"
      SSH_TARGET=$(sed -r 's/\s+//g' ${stat_file})  
      # SSH check
      if [[ "${INCOGNITO}" != "TRUE" ]]; then
        trace "Testing connection for ${SSH_TARGET}"
      else
        trace "Testing connection"
      fi
      SSH_STATUS=$(ssh -o BatchMode=yes -o ConnectTimeout=10 ${SSH_TARGET} echo ok 2>&1)
    fi

    if [[ "${SSH_STATUS}" == *"ok"* ]] ; then
      # Continue deploying
      trace "${SSH_TARGET}: OK"
    elif [[ "${SSH_STATUS}" == *"Permission denied"* ]] ; then
      # Not authorized, no key etc.
      error "Connection refused for ${SSH_TARGET}"
    else
      if [[ "${AUTOMATE}" == "1" ]]; then
        error "Connection for ${SSH_TARGET} not established, an unknown error occurred."
      else
        warning "Connection for ${SSH_TARGET} not established, an unknown error occurred."   
        # Ok now offer to re-run mina in verbose mode if someone is at the console
        # If FORCE=1 then simply exit
        if [[ "${FORCE}" == "1" ]] || yesno --default yes "Retry ${DEPLOY} in verbose mode? [Y/n] "; then
          eval "ssh ${SSH_TARGET}" | tee --append "${log_file}"
          # eval "${DEPLOY}" | tee --append "${log_file}"
        else
          error "Connection for ${SSH_TARGET} not established, an unknown error occurred."
        fi
      fi
    fi

    # Try to --simulate the command
    trace "Testing deployment command: ${DEPLOY_TEST}"

    # When using bundle, make sure it exists
    if [[ "${DEPLOY_TEST}" == *"bundle"* ]]; then
      eval "bundle check" &>> /dev/null
      EXIT_CODE=$?;
      if [[ "${EXIT_CODE}" != 0 ]]; then
        warning "Could not locate Gemfile or .bundle/ directory, installing..." 
        eval "bundle install" | tee --append "${log_file}"
        eval "bundle check" &>> /dev/null
        EXIT_CODE=$?;
        if [[ "${EXIT_CODE}" != 0 ]]; then
          error "Problem with bundle gem (Error ${EXIT_CODE})"
        fi
      fi
    fi

    eval "${DEPLOY_TEST}" &>> /dev/null
    EXIT_CODE=$?; 
    if [[ "${EXIT_CODE}" != 0 ]]; then 
      warning "Deployment exited due to a configuration problem (Error ${EXIT_CODE})"
      error_msg="Deployment exited due to a configuration problem (Error ${EXIT_CODE})"
      error_exit
    fi
    trace "OK"
  fi
}
