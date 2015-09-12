#!/bin/bash
#
# func.sh
#
# Handles various setup, logging, and option flags
# Make sure this function is loaded up first
trace "Loading func.sh"

# Open a deployment session, ask for user confirmation before beginning
function go() {
	tput cnorm;
	cd $WORKPATH/$APP; \
	echo "deploy" $VERSION
	printf "Current working path is %s\n" ${WORKPATH}/${APP}

	# Chill and wait for user to confirm project
	if  [ "$FORCE" = "1" ] || yesno --default yes "Continue? [Y/n] "; then
		trace "Loading project."
	else
		quickExit
	fi
}

# Check that dependencies exist
function depCheck() {
	hash git 2>/dev/null || { echo >&2 "I require git but it's not installed. Aborting."; exit 1; }
}

# Check for modified files. This will hopefully find files modified a user *other*
# than the user currently executing the deploy command. Still looking into the best way to do this.
#function activCheck() {
# find . -mmin -10 -ls 
#}