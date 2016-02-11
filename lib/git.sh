#!/bin/bash
#
# git.sh
#
# Handles git related processes
trace "Loading git.sh"

# Assign a variable to represent .git/index.lock
gitLock="$WORKPATH/$APP/.git/index.lock"

# Make sure we're in a git repository.
function gitStart() {
	# Is git installed?
	hash git 2>/dev/null || {
		info "deploy" $VERSION "requires git to function properly."; 
		exit 1
	}

	# Directory exists?
	if [ ! -d $WORKPATH/$APP ]; then
		info $WORKPATH/$APP "is not a valid directory."
		exit 1
	else
		cd $WORKPATH/$APP; \
	fi

	# Check that .git exists
	if [ -f $WORKPATH/$APP/.git/index ]; then
		sleep 1
	else
		info "There is nothing at " $WORKPATH/$APP "to deploy."
		exit 1
	fi

	# If CHECKBRANCH is set, make sure current branch is correct.
	if [ -n "$CHECKBRANCH" ]; then 
		current_branch="$(git rev-parse --abbrev-ref HEAD)"
		if [[ "${current_branch}" != "${CHECKBRANCH}" ]]; then
			error "Must be on" $CHECKBRANCH "branch to continue deployment.";
		fi
	fi

	# Check for active files
	if [ "$FORCE" = "1" ]; then
		trace "Checking for active files"
		active_files=$(find $WORKPATH/$APP -mmin -$ACTIVECHECK)
		if [ ! -z "$active_files" ]; then
			trace "Recently changed files:" $active_files
			error "Code base has changed within the last 10 minutes. Halting deployment."
		fi
	fi

	# Try to clear out old git processes owned by this user
	killall -9 git &>> /dev/null
}

# Checkout master
function gitChkMstr() {
	if [ -z "$MASTER" ]; then
		emptyLine; error "deploy" $VERSION "requires a master branch to be defined.";
	else
		notice "Checking out master branch..."
		if [[ $VERBOSE -eq 1 ]]; then
			git checkout master | tee --append $logFile            
		else
			if [ "${QUIET}" != "1" ]; then
				git checkout master &>> $logFile &
				showProgress
			else
				git checkout master &>> $logFile
			fi
		fi
	fi
}

# Does anything need to be committed? (Besides me?)
function gitStatus() {
	trace "Check Status"
	if [[ -z $(git status --porcelain) ]]; then
		console "Nothing to commit, working directory clean."; quietExit
	fi
}

# Stage files
function gitStage() {
	# Check for stuff that needs a commit
	if [[ -z $(git status --porcelain) ]]; then
		console "Nothing to commit, working directory clean."; quietExit
	else
		trace "Staging files"; emptyLine
		if [ "$FORCE" = "1" ] || yesno --default yes "Stage files? [Y/n] "; then
			if [[ $VERBOSE -eq 1 ]]; then
				git add -A | tee --append $logFile; errorChk              
			else  
				git add -A &>> $logFile; errorChk
			fi
		else
			trace "Exiting without staging files"; userExit    
		fi
	fi
}

# Commit, with message
function gitCommit() {
	# Smart commit stuff
	smrtCommit; emptyLine

	# Do a dry run; check for anything to commit
	git commit --dry-run &>> $logFile; 
	if grep -q "nothing to commit, working directory clean" $logFile; then 
		info "Nothing to commit, working directory clean."
		safeExit
	else
		# Found stuff, let's get a commit message
		if [[ -z "$COMMITMSG" ]]; then
			# while read -p "Enter commit message: " notes && [ -z "$notes" ]; do :; done
			read -p "Enter commit message: " notes
			if [[ -z "$notes" ]]; then
				console "Commit message must not be empty."
				read -p "Enter commit message: " notes
				if [[ -z "$notes" ]]; then
					console "Really?"
					read -p "Enter commit message: " notes
				fi
				if [[ -z "$notes" ]]; then
					console "Last chance."
					read -p "Enter commit message: " notes
				fi
				if [[ -z "$notes" ]]; then
					quickExit
				fi
			fi
		else
			# If running in -Fu (force updates only) mode, grab the Smart Commit 
			# message and skip asking for user input. Nice for cron updates. 
			if [ "$FORCE" = "1" ] && [ "$UPDATE" = "1" ]; then
				# We need Smart commits enabled or this can't work
				if [ "$SMARTCOMMIT" -ne "TRUE" ]; then
					console "Smart Commits must enabled when forcing updates."
					console "Set SMARTCOMMIT=TRUE in" $WORKPATH"/"$APP"/$CONFIGDIR/deploy.sh"; quietExit
				else
					if [ -z "$COMMITMSG" ]; then
						info "Commit message must not be empty."; quietExit
					else
						notes=$COMMITMSG
					fi
				fi
			else
				# We want to be able to edit the default commit if available
				if [[ $FORCE != "1" ]]; then
					notes=$COMMITMSG
					read -p "Edit commit message: " -e -i "${COMMITMSG}" notes
					# Update the commit message based on user input ()
					notes=${notes:-$COMMITMSG}
				else
					info "Using auto-generated commit message:" $COMMITMSG
					notes=$COMMITMSG
				fi
				trace "Oh gosh. Nested if/thens. Halp."
			fi
		fi
		git commit -m "$notes" &>> $logFile; errorChk
		trace "Commit message:" $notes
	fi
}

# Push master
function gitPushMstr() {
	if [ -n "$MASTER" ]; then
		trace "Pushing master."
		emptyLine  
		if [[ $VERBOSE -eq 1 ]]; then
			git push | tee --append $logFile; errorChk           
		else
			if  [ "$FORCE" = "1" ] || yesno --default yes "Push master branch? [Y/n] "; then
				if [ "$NOKEY" != "TRUE" ]; then
					if [ "${QUIET}" != "1" ]; then
						git push &>> $logFile &
						spinner $!
						info "Success.    "
					else
						git push &>> $logFile; errorChk
					fi
				else
					git push &>> $logFile; errorChk
				fi
			else
				safeExit
			fi
		fi
	fi
}

# Checkout production
function gitChkProd() {
	if [ -n "$PRODUCTION" ]; then
		notice "Checking out production branch..."
		if [[ $VERBOSE -eq 1 ]]; then
			git checkout production | tee --append $logFile; errorChk               
		else
			if [ "${QUIET}" != "1" ]; then
				git checkout production &>> $logFile &
				showProgress
			else
				git checkout production &>> $logFile; errorChk
			fi
		fi 
		# Were there any conflicts checking out?
		if grep -q "error: Your local changes to the following files would be overwritten by checkout:" $logFile; then
			 error "There is a conflict checking out."
		else
			trace "OK"
		fi
	fi
}

# Merge master into production
function gitMerge() {
	if [ -n "$PRODUCTION" ]; then
		notice "Merging master into production..."
		# Clear out the index.lock file, cause reasons
		[[ -f $gitLock ]] && rm "$gitLock"
		# Bonus add, just because. Ugh.
		git add -A; errorChk 
		if [[ $VERBOSE -eq 1 ]]; then
			git merge --no-edit master | tee --append $logFile              
		else
			if [ "${QUIET}" != "1" ]; then
				git merge --no-edit master &>> $logFile &
				showProgress
			else
				git merge --no-edit master &>> $logFile; errorChk
			fi
		fi
	fi
}

# Push production
function gitPushProd() {
	if [ -n "$PRODUCTION" ]; then
		trace "Push production"; emptyLine
		if [[ $VERBOSE -eq 1 ]]; then
			git push | tee --append $logFile; errorChk 
			trace "OK"              
		else
			if  [ "$FORCE" = "1" ] || yesno --default yes "Push production branch? [Y/n] "; then
				if [ "${QUIET}" != "1" ]; then
					git push &>> $logFile &
					spinner $!
				else
					git push &>> $logFile; errorChk
				fi
				# info "Success.    "
				# trace "OK"
				# Try a second push just cause reasons. Ugh.
				# git push &>> $logFile
				sleep 1
			else
				safeExit
			fi
		fi
	fi
}

# Get the stats for this git author, just for fun
function gitStats() {
	if [ "${GITSTATS}" == "TRUE" ]; then
		info "Calculating..."
		getent passwd $USER | cut -d ':' -f 5 | cut -d ',' -f 1 > $trshFile
		FULLUSER=$(<$trshFile)
		git log --author="$FULLUSER" --pretty=tformat: --numstat | \
		gawk '{ add += $1 ; subs += $2 ; loc += $1 - $2 } END \
		{ printf "Your total lines of code contributed so far: %s\n(+%s added | -%s deleted)\n",loc,add,subs }' -
	fi
} 
