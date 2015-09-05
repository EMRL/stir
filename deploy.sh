#!/bin/bash
#
# deploy: A simple bash script for deploying sites.
#
#
# Load external stuff

SITE=$1 		# This is going to change - I want to add switches

# Load external configuration & functions
deployPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
libLocation="${deployPath}/lib/loader.sh"
etcLocation="${deployPath}/etc/deploy.conf"

if [ -f "${etcLocation}" ]; then
    source "${etcLocation}"
else
	error "Unable to load configuration, exiting."
	exit 1
fi

if [ -f "${libLocation}" ]; then
    source "${libLocation}"
else
	error "Unable to load libraries, exiting."
	exit 1
fi

trace "deploy version" $VERSION
trace "Development workpath is" $WORKPATH
trace "Running from" $deployPath
trace "Loader found at" $libLocation

gitcheck    	# Check for a valid git project
lock        	# Create lock file
go   			# Start a deployment work session
pmfix       	# Fix permissions
gitcm			# Checkout master branch
wp 				# Run Wordpress upgrades if needed







exit