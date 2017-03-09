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

	# Slack test
	if [ "${SLACKTEST}" == "1" ]; then
		slackTest; quickExit
	fi

	# Email test
	if [ "${EMAILTEST}" == "1" ]; then
		emailTest; quickExit
	fi

	# Chill and wait for user to confirm project
	if  [ "${FORCE}" = "1" ] || yesno --default yes "Continue? [Y/n] "; then
		trace "Loading project"
	else
		quickExit
	fi
	if [ "${DONOTDEPLOY}" = "TRUE" ]; then
		info "This project is currently locked, and can't be deployed."
		warning "Canceling."; quickExit
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
		trace "Checking index..."
		if [ -w "${WORKPATH}/${APP}/.git/index" ]; then
			trace "OK"
		else
			trace "Index is not writable, attempting to fix..."
			sudo chmod 777 "${WORKPATH}/${APP}/.git/index" ; errorChk
			if [ -w "${WORKPATH}/${APP}/.git/index" ]; then
				trace "OK"
			else
				error "Unable to write new index file."; 
			fi
		fi
		sleep 1
	fi
}

# Check that dependencies exist
function depCheck() {
	# Is git installed?
	hash git 2>/dev/null || {
		error "deploy ${VERSION} requires git to function properly." 
	}

	# If a deploy command is declared, check that it actually exists.
	# This is probably not the best way to do this but for now it works. It 
	# strips everything after the first space that is declared in DEPLOY and
	# then checks that it's a valid command.
	if [ ! -z "${DEPLOY}" ]; then
		deploy_cmd=$(echo "$DEPLOY" | head -n1 | awk '{print $1;}')
		hash "${deploy_cmd}" 2>/dev/null || { 
			error >&2 "Unknown deployment command: ${DEPLOY} (${deploy_cmd} not found)"; 
		}
	fi

	# Do we need Sendmail, and if so can we find it?
	if [ "${EMAILERROR}" == "TRUE" ] || [ "${EMAILSUCCESS}" == "TRUE" ] || [ "${EMAILQUIT}" == "TRUE" ] || [ "${NOTIFYCLIENT}" == "TRUE" ]; then
		hash "${MAILPATH}"/sendmail 2>/dev/null || {
			error "deploy ${VERSION} requires Sendmail to function properly with your current configuration."
		}
	fi
}
