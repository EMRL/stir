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
		mina --simulate deploy &>> /dev/null
		EXITCODE=$?; 
		if [[ "${EXITCODE}" != 0 ]]; then 
			warning "Deployment exited due to a configuration problem (Error ${EXITCODE})"
			error_msg="Deployment exited due to a configuration problem (Error ${EXITCODE})"
			errorExit
		fi
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
