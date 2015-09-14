#!/bin/bash
#
# errorChk()
#
# Handles various exit code checking
trace "Loading errorChk()"

# Try to get exit/error code
function errorChk() {
	EXITCODE=$?; 
	if [[ $EXITCODE == 1 ]]; then 
		trace "FAIL"; warning "Exiting on ERROR CODE=1"
		errorExit 
		else
	# If exit code is not 1
	if
		[[ $EXITCODE == 0 ]]; then 
		trace "OK"; console "Success."
	fi
fi
}