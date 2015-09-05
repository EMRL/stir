#!/bin/bash
#
# deploy: A simple bash script for deploying sites.
#
#
# Load external stuff

SITE=$1 # This is going to change - I want to add switches

# Load external functions
deployPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
libLocation="${deployPath}/lib/loader.sh"
etcLocation="${deployPath}/etc/deploy.conf"

#echo; echo "DEBUG: Running from" $deployPath
#echo "DEBUG: Loader found at" $libLocation

if [ -f "${etcLocation}" ]; then
    source "${etcLocation}"
else
  echo "Unable to load configuration, exiting."
  exit 1
fi

if [ -f "${libLocation}" ]; then
    source "${libLocation}"
else
  echo "Unable to load libraries, exiting."
  exit 1
fi

gitcheck    # Check for a valid git project
lock        # Create lock file
pmfix       # Fix permissions


exit