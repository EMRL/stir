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
		grep -vE "(Notice:|Warning:|Strict Standards:)" $logFile > $postFile
		cat $postFile > $logFile
	fi
	# Content-type can be text/plain or text/html, working o swichtes
	cat $logFile | mail -s "$(echo -e $SUBJECT "-" ${APP^^}"\nContent-Type: text/plain")" $TO
}