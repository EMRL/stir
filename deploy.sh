#!/bin/bash
#
# deploy: A simple bash script for deploying sites.
#
#
# Load external stuff

VERSION=2.0.1
USAGE="Usage: deploy [NAME]"

# Load excternal functions
deployPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
libLocation="${deployPath}/lib/loader.sh"

echo $deployPath
echo $libLocation

if [ -f "${libLocation}" ]; then
    echo "DEBUG: Loading external functions..."
    source $deployPath/lib/pmfix.sh
else
  echo "Unable to load libraries, exiting."
  exit 1
fi




