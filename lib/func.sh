#!/bin/bash
#
# func.sh
#
# Handles various setup, logging, and option flags 

# Make sure this function is loaded up first
function trace () {
  if [[ $VERBOSE -eq 1 ]]; then
    echo "TRACE: $@"
  fi
}

function usage() {
  echo -n "deploy [OPTION]... [PROJECT]...

  A web app deployment script designed for EMRL's local development workflow.

  Options:
  -f, --force       Skip all user interaction.  Implied 'Yes' to all actions.
  -v, --verbose     Output more information. (Items echoed to 'verbose')
  -d, --debug       Runs script in BASH debug mode (set -x)
  -h, --help        Display this help and exit
  -v, --version     Output version information and exit
  "
}

function go() {			# Open a deployment session, ask for user confirmation before beginning
cd $WORKPATH/$APP; \
echo "deploy" $VERSION
printf "Current working path is %s\n" ${WORKPATH}/${APP}
echo
if yesno --default yes "Continue? [Y/n] "; then
  echo ""
else
  echo "Exiting."
  exit
fi
}