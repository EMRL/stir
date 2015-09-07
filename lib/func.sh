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

  if  [ "$FORCE" = "1" ] || yesno --default yes "Continue? [Y/n] "; then
    trace "Loading project."
  else
    safeExit
  fi
}

# Try to get exit code
function exitStatus() {
  rc=$?; 
  if [[ $rc != 0 ]]; then 
    error "Exiting on error." 
    if  yesno --default yes "Would you like to view the log file? [Y/n] "; then
      less $logFile; mailLog
      exit 1
    else
      mailLog; exit 1
    fi
  fi
  if
    [[ $rc == 0 ]]; then 
    info "Successful. "
  fi
}


# Progress spinner; we'll see if this works
function spinner() {
  local pid=$1
  local delay=0.15
  local spinstr='|/-\'
  tput civis;
  while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
    local temp=${spinstr#?}
    printf "Working... %c  " "$spinstr"
    local spinstr=$temp${spinstr%"$temp"}
    sleep $delay
    printf "\b\b\b\b\b\b\b\b\b\b\b\b\b\b"
  done
  printf "    \b\b\b\b"
  tput cnorm;
}

# Progress bar
function ProgressBar() {
  let _progress=(${1}*100/${2}*100)/100
  let _done=(${_progress}*4)/10
  let _left=40-$_done
  _fill=$(printf "%${_done}s")
  _empty=$(printf "%${_left}s")
  printf "\rProgress : [${_fill// /#}${_empty// /-}] ${_progress}%%"
}

# Log via email, needs work
function mailLog {
  mail -s "Content-Type: text/plain; charset=UTF-8" -s "$SUBJECT: $APP" $TO < $logFile
}

# User-requested exit
function userExit() {
  rm $WORKPATH/$APP/.git/index.lock &> /dev/null
  echo; info "Exiting."
  # check the email settings
  if [ "${EMAILQUIT}" == "1" ]; then
      mailLog
  fi
  # Clean up your mess
  rm $logFile
  #tput rmcup   # I'm not sure if I really want to use this or not.
  tput cnorm; exit 0
}

# Exit on error
function errorExit() {
  info "Exiting on error - check" $logFile "for more information."
  rm $WORKPATH/$APP/.git/index.lock &> /dev/null
  # check the email settings
  if [ "${EMAILERROR}" == "1" ]; then
      mailLog
  fi
  # Clean up your mess
  rm $logFile
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
  rm $logFile
  #tput rmcup   # I'm not sure if I really want to use this or not.
  tput cnorm; exit 0
}