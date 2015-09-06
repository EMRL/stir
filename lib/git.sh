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
	notice "Checking out master branch..."

  if [[ $VERBOSE -eq 1 ]]; then
    git checkout master | tee --append $logFile               
  else
    git checkout master &>> $logFile &
    _start=1
    _end=100
    for number in $(seq ${_start} ${_end})
    do
    ProgressBar ${number} ${_end}
    done;
  fi 
  emptyLine
}

# Stage files
function gitStage() {
	emptyLine
    if yesno --default yes "Stage files [Y/n] "; then
    	emptyLine
    	git add -A &>> $logFile &
        if grep -q "fatal: Unable to create '$WORKPATH/$APP/.git/index.lock': File exists." $logFile; then
          error "Unable to create '$WORKPATH/$APP/.git/index.lock': File exists."
        else
          trace "Files staged successfully."
        fi
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
	notice "Checking out production branch..."
  git checkout production  &>> $logFile &
  _start=1
  _end=100
  for number in $(seq ${_start} ${_end})
  do
    ProgressBar ${number} ${_end}
  done; 
  emptyLine
}

# Merge master into production
function gitMerge() {
	notice "Merging master into production..."
  git merge master  &>> $logFile &
  _start=1
  _end=100
  for number in $(seq ${_start} ${_end})
  do
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