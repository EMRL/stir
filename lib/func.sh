#!/bin/bash
#
# func.sh
#
# Handles various setup, logging, and option flags
# Make sure this function is loaded up first
trace "Loading func.sh"

# Open a deployment session, ask for user confirmation before beginning
function go() {
  tput cnorm;
  cd $WORKPATH/$APP; \
  echo "deploy" $VERSION
  printf "Current working path is %s\n" ${WORKPATH}/${APP}

  # Chill and wait for user to confirm project
  if  [ "$FORCE" = "1" ] || yesno --default yes "Continue? [Y/n] "; then
    trace "Loading project."
  else
    quickExit
  fi
}

# Check that dependencies exist
function depCheck() {
  hash git 2>/dev/null || { echo >&2 "I require git but it's not installed. Aborting."; exit 1; }
}

# Check for modified files. This will hopefully find files modified a user *other*
# than the user currently executing the deploy command. Still looking into the best way to do this.
#function activCheck() {
# find . -mmin -10 -ls 
#}

# Try to get exit/error code
function errorChk() {
  rc=$?; 
  if [[ $rc != 0 ]]; then 
    trace "FAIL"; warning "Exiting on ERROR CODE=1"
    errorExit 
    else
  # If exit code is not 1
  if
    [[ $rc == 0 ]]; then 
    trace "OK"; console "Success."
  fi
fi
}

# User-requested exit
function userExit() {
  rm $WORKPATH/$APP/.git/index.lock &> /dev/null
  trace "Exit on user request"
  # check the email settings
  if [ "${EMAILQUIT}" == "1" ]; then
      mailLog
  fi
  # Clean up your mess
  rm $logFile; rm $postFile; rm $trshFile
  #tput rmcup   # I'm not sure if I really want to use this or not.
  tput cnorm; exit 0
}

# Quick exit, never send log. Ever.
function quickExit() {
  # Clean up your mess
  rm $WORKPATH/$APP/.git/index.lock &> /dev/null
  rm $logFile; rm $postFile; rm $trshFile
  #tput rmcup   # I'm not sure if I really want to use this or not.
  tput cnorm; exit 0
}

# Exit on error
function errorExit() {
  if  yesno --default yes "Would you like to view the log file? [Y/n] "; then
    less $logFile;
  fi
  # Send log
  if [ "${EMAILERROR}" == "1" ]; then
    mailLog
  fi
  # Clean up your mess
  rm $WORKPATH/$APP/.git/index.lock &> /dev/null
  rm $logFile; rm $postFile; rm $trshFile
  #tput rmcup   # I'm not sure if I really want to use this or not.
  tput cnorm; exit 1
}

# Clean exit
function safeExit() {
  info "Exiting."
  # check the email settings
  if [ "${EMAILSUCCESS}" == "1" ]; then
      mailLog
  fi
  # Clean up your mess
  rm $logFile; rm $postFile; rm $trshFile
  #tput rmcup   # I'm not sure if I really want to use this or not.
  tput cnorm; exit 0
}