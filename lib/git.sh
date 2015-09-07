#!/bin/bash
#
# git.sh
#
# Handles git related processes
trace "Loading git functions"

# Make sure we're in a git repository.
function gitCheck() {
  # Directory is deal?
  if [ ! -d $WORKPATH/$APP ]; then
    info $WORKPATH/$APP "is not a valid directory."
    exit 1
  fi

  # Check that .git exists
  if [ -f $WORKPATH/$APP/.git/index ]; then
    sleep 1
  else
    info "There is nothing at " $WORKPATH/$APP "to deploy."
    exit 1
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
  if [ "$FORCE" = "1" ] || yesno --default yes "Stage files? [Y/n] "; then

    if [[ $VERBOSE -eq 1 ]]; then
        git add -A | tee --append $logFile; exitStatus              
    else  
      git add -A &>> $logFile; exitStatus
    fi
  else
    safeExit    
  fi
}

# Commit, with message
function gitCommit() {
  emptyLine
  read -p "Enter your notes on this commit: " notes
  git commit -m "$notes" &>> $logFile; exitStatus
  trace "Commit message:" $notes
}

# Push master
function gitPushm() {
  trace "Pushing master."
  emptyLine  
  if [[ $VERBOSE -eq 1 ]]; then
    git push | tee --append $logFile; exitStatus
  trace "Commit message:" $notes              
  else

    if  [ "$FORCE" = "1" ] || yesno --default yes "Push master branch to Bitbucket? [Y/n] "; then
      git push &>> $logFile &
      spinner $!
      info "Successful. "
    else
      safeExit
    fi
  fi
}

# Checkout production
function gitChkp() {
  notice "Checking out production branch..."
  if [[ $VERBOSE -eq 1 ]]; then
    git checkout production | tee --append $logFile               
  else
    git checkout production  &>> $logFile &
    _start=1
    _end=100
    for number in $(seq ${_start} ${_end}); do
    ProgressBar ${number} ${_end}
    done;
    emptyLine
  fi
}

# Merge master into production
function gitMerge() {
  notice "Merging master into production..."
  if [[ $VERBOSE -eq 1 ]]; then
    git merge master | tee --append $logFile               
  else
    git merge master  &>> $logFile &
    _start=1
    _end=100
    for number in $(seq ${_start} ${_end}); do
    ProgressBar ${number} ${_end}
    done; 
    emptyLine
  fi
}

# Push production
function gitPushp() {
  emptyLine
  if [[ $VERBOSE -eq 1 ]]; then
    git push | tee --append $logFile               
  else
    
    if  [ "$FORCE" = "1" ] || yesno --default yes "Push production branch to Bitbucket? [Y/n] "; then
      git push &>> $logFile &
      spinner $!
      info "Successful. "
    else
      safeExit
    fi
  fi
}