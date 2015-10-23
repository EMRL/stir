#!/bin/bash
#
# smrtCommit()
#
# Check to see if production environment is online and running its Apache server
trace "Loading serverChk()"

function serverChk() {
	if [[ -z "${PRODURL}" ]]; then
		trace "No production URL set, skipping check"
	else
		# Should return "200 OK" if all is working well
		notice "Checking server status..."
		wget --spider $PRODURL > $trshFile 2>&1
		if grep -q "200 OK" $trshFile; then
			info $PRODURL "online."
		else
			console; warning "Production environment may be having technical difficulties."
			info "Bring" $PRODURL "online before deploying."; quickExit
		fi
	fi
}