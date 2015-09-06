#!/bin/bash
#
# deploy: A simple bash script for deploying sites.
#
#
VERSION="2.0.1"
INSTALL="/home/fdiebel/deploy"

# Options
function usage() {
  echo -n "deploy [OPTION]... [PROJECT]...

An application deployment script designed for EMRL's local development workflow.

Options:
  --force           Skip all user interaction.  Implied 'Yes' to all actions.
  -q, --quiet       Quiet (no output)
  -l, --log         Print log to file
  -s, --strict      Exit script with null variables.  i.e 'set -o nounset'
  -V, --verbose     Output more information. (Items echoed to 'verbose')
  -d, --debug       Runs script in BASH debug mode (set -x)
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
    -v|--version) echo "$(basename $0) ${version}"; exit ;;
    -V|--verbose) VERBOSE=1 ;;
    -l|--log) printLog=1 ;;
    -q|--quiet) quiet=1 ;;
    -s|--strict) strict=1;;
    -d|--debug) debug=1;;
    --force) force=1 ;;
    --endopts) shift; break ;;
    *) die "invalid option: '$1'." ;;
  esac
  shift
done

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

trace "Version" $VERSION
trace "Development workpath is" $WORKPATH
trace "Lead developer permissions are" $DEV.$GRP
trace "Apache permissions are" $APACHEUSER.$APACHEGRP
trace "Running from" $deployPath
trace "Current project is" $APP
trace "Loader found at" $libLocation
trace "Logfile is" $logFile

function appDeploy {
  gitCheck        # Check for a valid git project
  lock            # Create lock file
  go   			      # Start a deployment work session
  permFix       	# Fix permissions
  gitChkm			    # Checkout master branch
  wpPkg 			    # Run Wordpress upgrades if needed
  pm              # Run node package management, or grunt
  gitStage        # Stage files
  gitCommit       # Commit, with message
  gitPushm        # Push master to Bit Bucket
  gitChkp         # Checkout production branch
  gitMerge        # Merge master into production
  gitPushp        # Push production to Bit Bucket
  gitChkm        # checkout master once again  
  minaDeploy      # Deploy project to live server   
}

# Trapping stuff will go here
#
# Execute the deploy process
appDeploy

# All done
safeExit