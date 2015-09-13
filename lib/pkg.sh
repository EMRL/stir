#!/bin/bash
#
# pkg.sh
#
# Handles deployment via mina
trace "Loading pkg.sh"   

function preDeploy() {
	# If there are changes waiting in the repo, stop and ask for user input
	# This should probably be it's own function
	if [[ -z $(git status  f--porcelain) ]]; then
		trace "Status looks good"
	else
		emptyLine;
		warning "There are undeployed changes in this project."
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
} 

function pkgDeploy() {
	emptyLine
	if  [ "$FORCE" = "1" ] || yesno --default yes "Deploy to live server? [Y/n] "; then
		# Add ssh keys and double check directoy
		cd $WORKPATH/$APP; \
		ssh-add &>> $logFile; sleep 2
		# Deploy via deployment command specified in mina
		if [[ $VERBOSE -eq 1 ]]; then
			$DEPLOY | tee --append $logFile
			# git show --stat &>> $logFile 
			postDeploy
		else
			$DEPLOY &>> $logFile &
			spinner $!
			# git show --stat &>> $logFile
			postDeploy
		fi
	fi   
}

function postDeploy() {
	# We just attempted to deploy, check for changes sitll waiting in the repo
	# if we find any, something went wrong.
	if [[ -z $(git status -uno --porcelain) ]]; then
		info "Deployment Success." 
		# Run integration hooks
		postCommit
	else
		info ""
		if  yesno --default yes "Attempted deploy, but something went wrong, view status? [Y/n] "; then
			git status; errorExit
		else
			errorExit
		fi
	fi
} 