#!/bin/bash
#
# git.sh
#
# Handles git related processes
trace "Loading git functions"

# Make sure we're in a git repository.
function gitCheck() {
	if [ ! -d $WORKPATH/$APP ]; then
  		error $WORKPATH/$APP "is not a valid directory."
   		exit
	fi

	if [ -f $WORKPATH/$APP/.git/index ]; then
	    sleep 1
	else
   		error "There is nothing at " $WORKPATH/$APP "to deploy."
   		exit
	fi
}

# Checkout master
function gitChkm() {
	notice "${green}Checking out master branch...${endColor}"
	 _start=1
  _end=100
  for number in $(seq ${_start} ${_end})
  do
    git checkout master 2>/dev/null 1>> $logFile &
    ProgressBar ${number} ${_end}
  done; 
  emptyLine
}

# Stage files
function gitStage() {
	emptyLine
    if yesno --default yes "Stage files [Y/n] "; then
    	emptyLine
    	git add -A
    else
		safeExit    
	fi
}

# Commit, with message
function gitCommit() {
	emptyLine
    read -p "Enter your notes on this commit: " notes
    git commit -m "$notes"
}

# Push master
function gitPushm() {
    emptyLine
    if yesno --default yes "Push master branch to Bitbucket? [Y/n] "; then
    	emptyLine
    	git push
    else
       safeExit
    fi
}

# Checkout production
function gitChkp() {
	notice "${green}Checking out production branch...${endColor}"
   _start=1
  _end=100
  for number in $(seq ${_start} ${_end})
  do
    git checkout production 2>/dev/null 1>> $logFile &
    ProgressBar ${number} ${_end}
  done; 
  emptyLine
}

# Merge master into production
function gitMerge() {
	notice "${green}Merging master into production...${endColor}"
   _start=1
  _end=100
  for number in $(seq ${_start} ${_end})
  do
    git merge master 2>/dev/null 1>> $logFile &
    ProgressBar ${number} ${_end}
  done; 
  emptyLine
}

# Push production
function gitPushp() {
    emptyLine
    if yesno --default yes "Push production branch to Bitbucket? [Y/n] "; then
    	emptyLine
    	git push
    else
		safeExit
    fi
}