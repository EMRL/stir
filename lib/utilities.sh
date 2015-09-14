#!/bin/bash
#
# utilities.sh
#
# Handles various setup, logging, and option flags
# Make sure this function is loaded up first
trace "Loading utilities.sh"

# Open a deployment session, ask for user confirmation before beginning
function go() {
	tput cnorm;
	cd $WORKPATH/$APP; \
	echo "deploy" $VERSION
	printf "Current working path is %s\n" ${WORKPATH}/${APP}

	# Does a configuration file for this repo exist?
	if [ -z "${APPRC}" ]; then
		if [ ! -d $WORKPATH/$APP/config ]; then
			sudo mkdir $WORKPATH/$APP/config
		fi
		emptyLine; info "Project configuration not found, creating."; sleep 2
		sudo cp ${deployPath}/deploy.sh $WORKPATH/$APP/config/
		sudo chown $DEVUSER.$DEVGROUP $WORKPATH/$APP/config/deploy.sh
		if yesno --default yes "Would you like to edit the configuration file now? [Y/n] "; then
			sudo nano $WORKPATH/$APP/config/deploy.sh
			clear; sleep 1
			info "Loading new project configuration."
			if [ -r $WORKPATH/$APP/config/deploy.sh ]; then
				source $WORKPATH/$APP/$CONFIGDIR/deploy.sh; APPRC=1
			fi
		else
			info "You can change configuration later be editing" $WORKPATH/$APP/"config/deploy.sh"
		fi
	fi

	# Chill and wait for user to confirm project
	if  [ "$FORCE" = "1" ] || yesno --default yes "Continue? [Y/n] "; then
		trace "Loading project."
	else
		quickExit
	fi
	if [ "$DONOTDEPLOY" = "TRUE" ]; then
		info "This project is currently locked, and can't be deployed."
		warning "Cancelling."; quickExit
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