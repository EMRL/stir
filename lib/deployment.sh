#!/bin/bash
#
# deployment.sh
#
# Handles deployment via mina
trace "Loading deployment.sh"   

function preDeploy() {
	# If there are changes waiting in the repo, stop and ask for user input
	# This should probably be it's own function
	if [[ -z $(git status --porcelain) ]]; then
		trace "Status looks good"
	else
		# If running in --force mode we will not allow deployment to continue
		if [[ "$FORCE" = "1" ]]; then
			emptyLine
			error "There are previously undeployed changes in this project, deployment can not continue."
		else
			emptyLine
			warning "There are previously undeployed changes in this project."

			if yesno --default no "View unresolved files? [y/N] "; then
				console; console " N = New | M = Modified | D = Deleted"
				console " ------------------------------------ "
				git status --porcelain; echo
				if  yesno --default yes "Continue deploy? [Y/n] "; then
					trace "Continuing deploy"
				else
					userExit
				fi
				trace "Continuing deploy"
			fi
		fi
	fi
} 

function pkgDeploy() {
	emptyLine
	if [ -n "$DEPLOY" ]; then
		if  [ "$FORCE" = "1" ] || yesno --default yes "Deploy to live server? [Y/n] "; then
			# Add ssh keys and double check directoy
			cd $WORKPATH/$APP; \
			# Deploy via deployment command specified in mina
			if [[ $VERBOSE -eq 1 ]]; then
				$DEPLOY | tee --append $logFile
				#postDeploy
			else
				if [ "${QUIET}" != "1" ]; then
					$DEPLOY &>> $logFile &
					spinner $!
				else
					$DEPLOY &>> $logFile
				fi
				#postDeploy
			fi
		fi
	fi
	postDeploy
}

function postDeploy() {
	# We just attempted to deploy, check for changes sitll waiting in the repo
	# if we find any, something went wrong.
	if [[ -z $(git status -uno --porcelain) ]]; then
		# Run integration hooks
		postCommit; info "Deployment Success."
	else
		info ""
		if  yesno --default yes "Attempted deploy, but something went wrong, view details? [Y/n] "; then
			git status; errorExit
		else
			errorExit
		fi
	fi
} 
