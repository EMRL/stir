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

# Constructing smart *cough* commit messages
function smrtCommit() {
  if [[ $SMRTCOMMIT == 1 ]]; then
    trace "Building commit message"
    # Checks for the existence of a successful plugin upgrade, using grep
    PCA=$(grep '\<Success: Updated' $logFile | grep 'plugins')
    if [[ -z "$PCA" ]]; then
      trace "No plugin updates"
    else
      # Yanks out the "Success: "
      PCB=$(echo $PCA | sed 's/^.*\(Updated.*\)/\1/g')
      # Strips the last period, makes my head hurt.
      PCC=${PCB%?}; PCD=$(echo $PCB | cut -c 1-$(expr `echo "$PCC" | wc -c` - 2))
      trace "Plugin status ["$PCD"]"
      # Replace current commit message with Plugin upgrade info 
      COMMITMSG=$PCD
      # Will have to add the stuff for core upgrade, still need logs
      #
    fi
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
  # Filter as needed
  if [ "${NOPHP}" == "1" ]; then
    grep -vE "(Notice:|Warning:|Strict Standards:)" $logFile > $postFile
    cat $postFile > $logFile
  fi
  # Content-type can be text/plain or text/html, working o swichtes
  cat $logFile | mail -s "$(echo -e $SUBJECT ${APP^^}"\nContent-Type: text/plain")" $TO
}

# Try to get exit/error code
function errorChk() {
  rc=$?; 
  if [[ $rc != 0 ]]; then 
    trace "FAIL"; warning "Exiting on ERROR CODE=1" 
    if  yesno --default yes "Would you like to view the log file? [Y/n] "; then
      less $logFile; mailLog
      exit 1
    else
      mailLog; exit 1
    fi
  fi
  if
    [[ $rc == 0 ]]; then 
    trace "OK"; console "Success."
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
  rm $WORKPATH/$APP/.git/index.lock &> /dev/null
  # Clean up your mess
  rm $logFile; rm $postFile; rm $trshFile
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
