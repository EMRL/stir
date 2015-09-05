#!/bin/bash
#
# deploy: A simple bash script for deploying sites.
#
#
# Load external stuff

#SITE=$1 		# This is going to change - I want to add switches

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

# Create temp directory. Hopefully it will be deleted upon exit. 
tmpDir="/tmp/${scriptName}.$RANDOM.$RANDOM.$RANDOM.$$"
(umask 077 && mkdir "${tmpDir}") || {
  die "Could not create temporary directory! Exiting."
}

trace "Version" $VERSION
trace "Development workpath is" $WORKPATH
trace "Running from" $deployPath
trace "Loader found at" $libLocation

# If no arguments are passed, display help
[[ $# -eq 0 ]] && set -- "--help"

# Read the options and set stuff
while [[ $1 = -?* ]]; do
  case $1 in
    -h|--help) usage >&2; exit ;;
-v|--version) echo "$(basename $0) ${VERSION}"; exit ;;
-V|--verbose) VERBOSE=1;;
-d|--debug) debug=1;;
--force) force=1 ;;
--endopts) shift; break ;;
*) die "invalid option: '$1'." ;;
esac
shift
done

# Store the remaining part as arguments.
APP+=("$@")
trace "Application is" $APP

function coreDeploy {
  gitCheck    	# Check for a valid git project
  lock        	# Create lock file
  go   			    # Start a deployment work session
  permFix       	# Fix permissions
  gitChkm			    # Checkout master branch
  wPress 			  # Run Wordpress upgrades if needed
  pm           # Run node package management
}

# Trapping stuff will go here

# the deploy process
coreDeploy




exit