#!/bin/bash
#
# quit.sh
#
# Handles exiting the program
trace "Loading quit.sh"

# User-requested exit
function userExit() {
	rm $WORKPATH/$APP/.git/index.lock &> /dev/null
	trace "Exit on user request"
	# check the email settings
	if [ "${EMAILQUIT}" == "TRUE" ]; then
	   mailLog
	fi
	# Clean up your mess
	cleanUp
	#tput rmcup   # I'm not sure if I really want to use this or not.
	tput cnorm; exit 0
}

# Quick exit, never send log. Ever.
function quickExit() {
	# Clean up your mess
	cleanUp
	#tput rmcup   # I'm not sure if I really want to use this or not.
	tput cnorm; exit 0
}

# Exit on error
function errorExit() {
	if  yesno --default yes "Would you like to view the log file? [Y/n] "; then
		less $logFile;
	fi
	# Send log
	if [ "${EMAILERROR}" == "TRUE" ]; then
		mailLog
	fi
  	# Clean up your mess
	cleanUp
	#tput rmcup   # I'm not sure if I really want to use this or not.
	tput cnorm; exit 1
}

# Clean exit
function safeExit() {
	info "Exiting."; console
	# check the email settings
	if [ "${EMAILSUCCESS}" == "TRUE" ]; then
	   mailLog
	fi
	# Clean up your mess
	cleanUp
	#tput rmcup   # I'm not sure if I really want to use this or not.
	tput cnorm; exit 0
}

# Clean exit, nothing to commit
function quietExit() {
	info "Exiting."; console
	# Clean up your mess
	cleanUp
	#tput rmcup   # I'm not sure if I really want to use this or not.
	tput cnorm; exit 0
}

function cleanUp() {
	[[ -f $logFile ]] && rm "$logFile"
	[[ -f $trshFile ]] && rm "$trshFile"
	[[ -f $postFile ]] && rm "$postFile"
	[[ -f $statFile ]] && rm "$statFile"
	[[ -f $wpFile ]] && rm "$wpFile"
	[[ -f $urlFile ]] && rm "$urlFile"
	[[ -f $coreFile ]] && rm "$coreFile"
	[[ -f $gitLock ]] && rm "$gitLock"
	# Attempt to reset the terminal
	echo -e \\033c
}
