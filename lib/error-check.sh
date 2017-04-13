#!/bin/bash
#
# errorChk()
#
# Handles various exit code checking
trace "Loading error checking"

# Try to get exit/error code, with a hard stop on fail
function errorChk() {
	EXITCODE=$?; 
	if [[ "${EXITCODE}" != 0 ]]; then 
		warning "Exiting on error code ${EXITCODE}"
		error_msg="Exited on error code ${EXITCODE}"
		errorExit
	fi
}

function deployChk() {
	if [[ "${DEPLOY}" == *"mina"* ]]; then
		# Get variables organized
		grep -n "user" "${WORKPATH}/${APP}"/config/deploy.rb > "${trshFile}"
		MINAUSER=$(awk -F\' '{print $2,$4}' ${trshFile})
		echo -n "${MINAUSER}" > "${statFile}"
		echo -n "@" >> ${statFile}
		grep -n "domain" "${WORKPATH}/${APP}"/config/deploy.rb > "${trshFile}"
		MINADOMAIN=$(awk -F\' '{print $2,$4}' ${trshFile})
		echo -n "${MINADOMAIN}" >> "${statFile}"
		SSHTARGET=$(sed -r 's/\s+//g' ${statFile})
		
		# SSH check
		trace "Testing connection for ${SSHTARGET}"
		SSHSTATUS=$(ssh -o BatchMode=yes -o ConnectTimeout=10 ${SSHTARGET} echo ok 2>&1)

		if [[ "${SSHSTATUS}" == *"ok"* ]] ; then
			# Continue deploying
			trace "OK"
		elif [[ "${SSHSTATUS}" == *"Permission denied"* ]] ; then
			# Not authorized, no key etc.
			error "Connection refused for ${SSHTARGET}"
		else
			if [[ "${AUTOMATE}" == "1" ]]; then
				error "Connection for ${SSHTARGET} not established, an unknown error occurred."
			else
				warning "Connection for ${SSHTARGET} not established, an unknown error occurred."
				# Ok now re-run mina in verbose mode if someone is at the console

				# If FORCE=1 then simply exit
				if [[ "${FORCE}" == "1" ]] || yesno --default yes "Retry ${DEPLOY} in verbose mode? [Y/n] "; then
					eval "${DEPLOY}" | tee --append "${logFile}"
				else
					error "Connection for ${SSHTARGET} not established, an unknown error occurred."
				fi
			fi
		fi

		# Try to --simulate the command
		trace "Testing deployment command: ${DEPLOY}"
		mina --simulate deploy &>> /dev/null
		EXITCODE=$?; 
		if [[ "${EXITCODE}" != 0 ]]; then 
			warning "Deployment exited due to a configuration problem (Error ${EXITCODE})"
			error_msg="Deployment exited due to a configuration problem (Error ${EXITCODE})"
			errorExit
		fi
		trace "OK"
	fi
}

# Try to get exit/error code, with a hard stop on fail
function errorStatus() {
	EXITCODE=$?; 
	if [[ "${EXITCODE}" != 0 ]]; then 
		error_msg="WARNING: Error code ${EXITCODE}"
		trace "${error_msg}"
	else
		trace "OK"
	fi
}
