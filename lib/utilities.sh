#!/bin/bash
#
# utilities.sh
#
# Handles various setup, logging, and option flags
# Make sure this function is loaded up first
trace "Loading utilities"

# Open a deployment session, ask for user confirmation before beginning
function go() {
	if [ "${QUIET}" != "1" ]; then
		tput cnorm;
	fi
	console "deploy ${VERSION}"
	console "Current working path is ${WORKPATH}/${APP}"

	# Does a configuration file for this repo exist?
	if [ -z "${APPRC}" ]; then
		if [ ! -d "${WORKPATH}/${APP}/config" ]; then
			mkdir "${WORKPATH}/${APP}/config"
		fi
		emptyLine; info "Project configuration not found, creating."; sleep 2
		cp "${deployPath}"/deploy.sh "${WORKPATH}/${APP}/${CONFIGDIR}/"
		if yesno --default yes "Would you like to edit the configuration file now? [Y/n] "; then
			nano "${WORKPATH}/${APP}/${CONFIGDIR}/deploy.sh"
			clear; sleep 1
			quickExit
		else
			info "You can change configuration later by editing ${WORKPATH}/${APP}/config/deploy.sh"
		fi
	fi

	# Chill and wait for user to confirm project
	if  [ "${FORCE}" = "1" ] || yesno --default yes "Continue? [Y/n] "; then
		trace "Loading project."
	else
		quickExit
	fi
	if [ "${DONOTDEPLOY}" = "TRUE" ]; then
		info "This project is currently locked, and can't be deployed."
		warning "Cancelling."; quickExit
	fi

	# Force sudo password input if needed
	if [[ "${FIXPERMISSIONS}" == "TRUE" ]]; then
		sudo sleep 1
	fi

	# if git.lock exists, do we want to remove it?
	if [ -f "${gitLock}" ]; then
		warning "Found ${gitLock}"
		# If running in --force mode we will not allow deployment to continue
		if [[ "${FORCE}" = "1" ]]; then
			warning "Can't continue deployment in --force mode."; quietExit
		else
			if yesno --default no "Remove lockfile? [y/N] "; then
				rm -f "${gitLock}" 2>/dev/null
				sleep 1
			else
				quickExit
			fi
		fi
	fi
}

function fixIndex() {
	# A rather brutal fix for index permissions issues
	if [[ "${FIXINDEX}" == "TRUE" ]]; then
		trace "Checking Index"
		if [ -w "${WORKPATH}/${APP}/.git/index" ]; then
			trace "Looks good."
		else
			trace "Index is not writable, attempting to fix..."
			sudo chmod 777 "${WORKPATH}/${APP}/.git/index" ; errorChk
			if [ -w "${WORKPATH}/${APP}/.git/index" ]; then
				trace "Looks good."
			else
				error "Unable to write new index file."; 
			fi
		fi
		sleep 1
	fi
}

# Check that dependencies exist
function depCheck() {
	hash git 2>/dev/null || { echo >&2 "I require git but it's not installed. Aborting."; exit 1; }
}
