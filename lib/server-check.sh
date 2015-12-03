#!/bin/bash
#
# smrtCommit()
#
# Check to see if production environment is online and running its Apache server
trace "Loading serverChk()"

function serverChk() {
	notice "Checking servers..."
	# Set SERVERFAIL to 0
	SERVERFAIL="0"
	if [[ -z "${REPO}" ]]; then
		trace "No repo name set, skipping check"
	else
		# For now, we'll use 401 to indicate all is working well
		# I'll make this better later
		REPOURL=$BITBUCKET"/"$REPO"/"
		wget --spider --no-check-certificate $REPOURL > $trshFile 2>&1
		if grep -Eq '200 OK|401 UNAUTHORIZED' $trshFile; then
			info " "$BITBUCKET"/"$REPO"/ ${tan}OK${endColor}";
		else
			info " "$BITBUCKET"/"$REPO"/ ${red}FAIL${endColor}"; SERVERFAIL="1"
		fi
	fi

	if [[ -z "${DEVURL}" ]]; then
		trace "No development URL set, skipping check"
	else
		# Should return "200 OK" if all is working well
		wget --spider --no-check-certificate $DEVURL > $trshFile 2>&1
		if grep -q "200 OK" $trshFile; then
			info " "$DEVURL "(development) ${tan}OK${endColor}";
		else
			info " "$DEVURL "(development) ${red}FAIL${endColor}"; SERVERFAIL="1"
		fi
	fi

	if [[ -z "${PRODURL}" ]]; then
		trace "No production URL set, skipping check"
	else
		# Should return "200 OK" if all is working well
		wget --spider --no-check-certificate $PRODURL > $trshFile 2>&1
		if grep -q "200 OK" $trshFile; then
			info " "$PRODURL "(production) ${tan}OK${endColor}"
		else
			info " "$PRODURL "(production) ${red}FAIL${endColor}"; SERVERFAIL="1"
		fi
	fi

	# Did anything fail?
	if [ "${SERVERFAIL}" == "1" ]; then
		console; warning "Fix server issues before continuing."; quietExit
	fi
}
