#!/bin/bash
#
# log-handling.sh
#
# Handles parsing and creating logs
trace "Loading log-handling.sh"

# Log via email, needs work
function mailLog {
	# Filter as needed
	if [ "${NOPHP}" == "TRUE" ]; then
		grep -vE "(PHP |Notice:|Warning:|Strict Standards:)" "${logFile}" > "${postFile}"
		cat "${postFile}" > "${logFile}"
	fi
	# This is HELLA UGLY
	# Content-type can be text/plain or text/html, working o swichtes
	mail -s "$(echo -e "${SUBJECT} - ${APP}""\n"Content-Type: text/plain)" "${TO}" < "${logFile}"
}
