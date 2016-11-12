#!/bin/bash
#
# server_check()
#
# Check to see if production environment is online and running its Apache server
trace "Loading server checks"

function server_check() {
	if [ "${SERVERCHECK}" == "TRUE" ]; then
		notice "Checking servers..."
		# Set SERVERFAIL to 0
		SERVERFAIL="0"
		if [[ -z "${REPO}" ]]; then
			trace "No repo name set, skipping check"
		else
			# For now, we'll use 200, 301, or 401 to indicate all is working well cause 
			# Bitbucket is being a noob; I'll make this better later
			REPOURL="${REPOHOST}/${REPO}/"
			if curl -sL --head "${REPOHOST}" | grep -E "200|301|401" > /dev/null; then
				info " $REPOHOST/$REPO/ ${tan}OK${endColor}";
			else
				info " $REPOHOST/$REPO/ ${red}FAIL${endColor}"; SERVERFAIL="1"
			fi
		fi

		if [[ -z "${DEVURL}" ]]; then
			trace "No development URL set, skipping check"
		else
			# Should return "200 OK" if all is working well
			if curl -sL --head "${DEVURL}" | grep "200 OK" > /dev/null; then
				info " ${DEVURL} (development) ${tan}OK${endColor}";
			else
				info " ${DEVURL} (development) ${red}FAIL${endColor}"; SERVERFAIL="1"
			fi
		fi

		if [[ -z "${PRODURL}" ]]; then
			trace "No production URL set, skipping check"
		else
			# Should return "200 OK" if all is working well
			if curl -sL --head "${PRODURL}" | grep "200 OK" > /dev/null; then
				info " ${PRODURL} (production) ${tan}OK${endColor}"
			else
				info " ${PRODURL} (production) ${red}FAIL${endColor}"; SERVERFAIL="1"
			fi
		fi

		# Did anything fail?
		if [ "${SERVERFAIL}" == "1" ]; then
			console; error "Fix server issues before continuing.";
		fi
	fi
}
