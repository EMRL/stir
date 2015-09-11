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
    exit 1
  }

  # Directory exists?
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

  # Try to clear out old git processes owned by this user
  killall -9 git &>> /dev/null

  # Unstage anything that is leftover from a mess
  git reset HEAD &>> $logFile
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

# Does anything need to be committed? (Besides me?)
function gitStatus() {
  trace "Check Status"
  if [[ $VERBOSE -eq 1 ]]; then
    git status | tee --append $logFile            
  else
    git status &>> $logFile &
  fi
  # Were there any conflicts checking out?
  if grep -q "nothing to commit, working directory clean" $logFile; then
     console "Nothing to commit, working directory clean."
     safeExit
  else
    trace "OK";
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
  # Do a dry run; check for anything to commit
  git commit --dry-run &>> $logFile; 
  if grep -q "nothing to commit, working directory clean" $logFile; then 
    info "Nothing to commit, working directory clean."
    safeExit
  else
    # Found stuff, let's get a commit message
    if [[ -z "$COMMITMSG" ]]; then
      while read -p "Enter commit message: " notes && [ -z "$notes" ]; do :; done
    else
      # We want to be able to edit the default commit if available
      notes=$COMMITMSG
      read -p "Enter commit message [$COMMITMSG]: " -e -i "${COMMITMSG}" notes
      # Update the commit message based on user input ()
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
  fi 
  # Were there any conflicts checking out?
  if grep -q "error: Your local changes to the following files would be overwritten by checkout:" $logFile; then
     error "There is a conflict checking out."
  else
    trace "OK"; emptyLine
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