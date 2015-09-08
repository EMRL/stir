#!/bin/bash
#
# git.sh
#
# Handles git related processes
trace "Loading git.sh"

# Make sure we're in a git repository.
function gitCheck() {

  # Is git installed?
  hash git 2>/dev/null || {
    info "deploy" $VERSION "requires git to function properly."; 
    errorExit
  }

  # Directory exists?
  if [ ! -d $WORKPATH/$APP ]; then
    info $WORKPATH/$APP "is not a valid directory."
    errorExit
  fi

  # Check that .git exists
  if [ -f $WORKPATH/$APP/.git/index ]; then
    sleep 1
  else
    info "There is nothing at " $WORKPATH/$APP "to deploy."
    errorExit
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
  # Were there any conflicts checking out?
  if grep -q "error: Your local changes to the following files would be overwritten by checkout:" $logFile; then
     error "There is a conflict checking out."
  else
    trace "OK"; emptyLine
  fi
}

# Stage files
function gitStage() {
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
}

# Commit, with message
function gitCommit() {
  # Check for stuff that needs a commit
  notice "Examining working directory..."

  # Smart commit stuff
  smrtCommit
  git commit --dry-run &>> $logFile; 
  if grep -q "nothing to commit, working directory clean" $logFile; then 
    info "Nothing to commit, working directory clean."
    safeExit
  else
    # Found stuff, let's get a commit message
    if [[ -z "$COMMITMSG" ]]; then
      while read -p "Enter commit message: " notes  && [ -z "$notes" ]; do :; done
    else
      read -p "Enter commit message [$COMMITMSG]: " notes 
      notes=${notes:-$COMMITMSG}
      git commit -m "$notes" &>> $logFile
      trace "Commit message:" $notes
    fi
  fi
}

# Push master
function gitPushm() {
  trace "Pushing master."
  emptyLine  
  if [[ $VERBOSE -eq 1 ]]; then
    git push | tee --append $logFile; errorChk           
  else

    if  [ "$FORCE" = "1" ] || yesno --default yes "Push master branch to Bitbucket? [Y/n] "; then
      git push &>> $logFile &
      spinner $!
      info "Success.    "
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
  trace "OK"
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
  trace "OK"
}

# Push production
function gitPushp() {
  trace "Push production"; emptyLine
  if [[ $VERBOSE -eq 1 ]]; then
    git push | tee --append $logFile 
    trace "OK"              
  else
    
    if  [ "$FORCE" = "1" ] || yesno --default yes "Push production branch to Bitbucket? [Y/n] "; then
      git push &>> $logFile &
      spinner $!
      info "Success.    "
      trace "OK"
    else
      safeExit
    fi
  fi
}