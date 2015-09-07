#!/bin/bash
#
# deploy: A simple bash script for deploying sites.
#
#
VERSION="3.0RC-alpha"
INSTALL="/home/fdiebel/deploy"

# Options
function usage() {
  echo -n "Usage: deploy [options] [target] ...

Options:
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

# Iterate over options breaking -ab into -a -b when needed and --foo=bar into
# --foo bar
optstring=h
unset options
while (($#)); do
  case $1 in
    # If option is of type -ab
    -[!-]?*)
      # Loop over each character starting with the second
      for ((i=1; i < ${#1}; i++)); do
        c=${1:i:1}
        # Add current char to options
        options+=("-$c")
        # If option takes a required argument, and it's not the last char make
        # the rest of the string its argument
        if [[ $optstring = *"$c:"* && ${1:i+1} ]]; then
          options+=("${1:i+1}")
          break
        fi
      done
      ;;
    # If option is of type --foo=bar
    --?*=*) options+=("${1%%=*}" "${1#*=}") ;;
    # add --endopts for --
    --) options+=(--endopts) ;;
    # Otherwise, nothing special
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

# Exit on empty variable, will usually get confused by git output
if [ "${STRICT}" == "1" ]; then
  set -e
fi

# Store the remaining part as arguments.
APP+=("$@")

# Fire up a log file
logFile="/tmp/$APP.$RANDOM.log"
(umask 077 && touch "${logFile}") || {
  echo "Could not create logfile, exiting."
  exit 1
}

# Load external configuration & functions
deployPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
libLocation="${INSTALL}/lib/loader.sh"
etcLocation="${INSTALL}/etc/deploy.conf"

# System wide configuration files
if [ -f "${etcLocation}" ]; then
  source "${etcLocation}"
else
  echo "Unable to load configuration, exiting."
  exit 1
fi

# Per-user configuration
if [ -r ~/.deployrc ]; then
  source ~/.deployrc
fi

if [ -f "${libLocation}" ]; then
  source "${libLocation}"
else
  echo "Unable to load libraries, exiting."
  exit 1
fi

trace "Version" $VERSION
trace "Development workpath is" $WORKPATH
trace "Lead developer permissions are" $DEVUSER.$DEVGRP
trace "Apache permissions are" $APACHEUSER.$APACHEGRP
trace "Running from" $deployPath
trace "Current project is" $APP
trace "Loader found at" $libLocation
trace "Logfile is" $logFile

function appDeploy {
  gitCheck        # Check for a valid git project
  lock            # Create lock file
  go              # Start a deployment work session
  permFix         # Fix permissions
  gitChkm         # Checkout master branch
  wpPkg           # Run Wordpress upgrades if needed
  pm              # Run node package management, or grunt
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