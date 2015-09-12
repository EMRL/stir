#!/bin/bash
#
# deploy: A simple bash script for deploying sites.
#
#
VERSION="3.0RC-beta"
NOW=$(date +"%m-%d-%Y")
DEV=$USER"@"$HOSTNAME

# Options
function usage() {
  echo -n "Usage: deploy [options] [target] ...

Options:
  -u, --upgrade     If there are no available upgrades, halt deployment
  -F, --force       Skip all user interaction, forces 'Yes' to all actions.
  -Q, --forcequiet  Like the --force command, with minimal output to screen
  -s, --strict      Run in Strict mode. Any error will halt deployment completely
  -V, --verbose     Output more process information to screen
  -d, --debug       Run in debug mode
  -h, --help        Display this help and exit
  -v, --version     Output version information and exit

"
}

# If no arguments are passed, display help
[[ $# -eq 0 ]] && set -- "--help"

# Grab options and parse their format
optstring=h
unset options
while (($#)); do
  case $1 in
    -[!-]?*)
      for ((i=1; i < ${#1}; i++)); do
        c=${1:i:1}
        options+=("-$c")
        if [[ $optstring = *"$c:"* && ${1:i+1} ]]; then
          options+=("${1:i+1}")
          break
        fi
      done
      ;;
    --?*=*) options+=("${1%%=*}" "${1#*=}") ;;
    --) options+=(--endopts) ;;
    *) options+=("$1") ;;
  esac
  shift
done
set -- "${options[@]}"
unset options

# Read the options
while [[ $1 = -?* ]]; do
  case $1 in
    -h|--help) usage >&2; exit ;;
    -u|--upgrade) UPGRADE=1 ;;
    -v|--version) echo "$(basename $0) ${VERSION}"; exit ;;
    -V|--verbose) VERBOSE=1 ;;
    -Q|--forcequiet) QUIET=1 ;;
    -s|--strict) STRICT=1 ;;
    -d|--debug) DEBUG=1 ;;
    -F|--force) FORCE=1 ;;
    --endopts) shift; break ;;
    *) echo "Invalid option: '$1'" 1>&2 ; exit 1 ;;
  esac
  shift
done

# Run in debug mode, if set
if [ "${DEBUG}" == "1" ]; then
  set -x
fi

# Exit on empty variable, will possibly get confused by git output
if [ "${STRICT}" == "1" ]; then
  set -e
fi

# Store the remaining part as arguments.
APP+=("$@")

# Fire up a log file, and trashfile
logFile="/tmp/$APP.$RANDOM.log"
(umask 077 && touch "${logFile}") || {
  echo "Could not create logfile, exiting."
  exit 1
}
echo -e "Deployment logfile for" ${APP^^} "-" $NOW "\r\r" >> $logFile
postFile="/tmp/$APP.$RANDOM.log"
(umask 077 && touch "${postFile}") || {
  echo "Could not create logfile, exiting."
  exit 1
}
trshFile="/tmp/$APP.trash.$RANDOM.log"
(umask 077 && touch "${trshFile}") || {
  echo "Could not create trash, exiting."
  exit 1
}
statFile="/tmp/$APP.stat.$RANDOM.log"
(umask 077 && touch "${statFile}") || {
  echo "Could not create stat file, exiting."
  exit 1
}

# Path of the script
if [ -d /etc/deploy ]; then
  deployPath=/etc/deploy
else
  deployPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
fi

# Load external configuration & functions
libLocation="${deployPath}/lib/loader.sh"
etcLocation="${deployPath}/deploy.conf"

# System wide configuration files
if [ -f "${etcLocation}" ]; then
  source "${etcLocation}"
else
  echo "Unable to load configuration file at" $etcLocation", exiting."
  exit 1
fi

# Load per-user configuration, if it exists
if [ -r ~/.deployrc ]; then
  source ~/.deployrc; USERRC=1
fi

# Load per-project configuration, if it exists
if [ -r $WORKPATH/$APP/config/deploy.sh ]; then
  source $WORKPATH/$APP/config/deploy.sh; APPRC=1
fi

# Load libraries, or die
if [ -f "${libLocation}" ]; then
  source "${libLocation}"
else
  echo "Unable to load libraries at" $libLocation", exiting."
  exit 1
fi

trace "Version" $VERSION
trace "Running from" $deployPath
trace "Loader found at" $libLocation
trace "Loading system configuration file from" $etcLocation

# Does a user configuration exit?
if [ "${USERRC}" == "1" ]; then
  trace "Loading user configuration from ~/.deployrc"
else
  trace "No user .deployrc found"
fi

# Does a project configuration exit?
if [ "${APPRC}" == "1" ]; then
  trace "Loading project configuration from" $WORKPATH"/"$APP"/config/deploy.sh"
else
  trace "No project config file found"
fi

# Are we using "smart" *cough* commits?
if [ "${SMRTCOMMIT}" == "1" ]; then
  trace "Smart commits are enabled"
else
  trace "Smart commits are disabled"
fi

# Are any integrations setup?
POSTEMAIL=$POSTEMAILHEAD$TASK$POSTEMAILTAIL
if [[ -z "$POSTEMAIL" ]]; then
  trace "No integration found"
else
  trace "Integration enabled, using" $POSTEMAIL
fi

trace "Development workpath is" $WORKPATH
trace "Lead developer permissions are" $DEVUSER.$DEVGRP
trace "Apache permissions are" $APACHEUSER.$APACHEGRP
trace "Current project is" $APP
trace "Current user is" $DEV
trace "Logfile is" $logFile


function  appDeploy {
  gitCheck        # Check for a valid git project
  lock            # Create lock file
  go              # Start a deployment work session
  permFix         # Fix permissions
  gitChkm         # Checkout master branch
  preDeploy       # Get the status
  wpPkg           # Run Wordpress upgrades if needed
  pm              # Run node package management, or grunt
  gitStatus       # Make sure there's anything here to commit
  gitStage        # Stage files
  gitCommit       # Commit, with message
  gitPushm        # Push master to Bit Bucket
  gitChkp         # Checkout production branch
  gitMerge        # Merge master into production
  gitPushp        # Push production to Bit Bucket
  gitChkm         # checkout master once again  
  pkgDeploy       # Deploy project to live server   
}

# Trapping stuff
trap userExit INT

# Execute the deploy process
appDeploy

# All done
safeExit