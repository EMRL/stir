#!/bin/bash
#
# display-styles.sh

# Define color codes
black='\E[30;47m'
red='\e[0;31m'
green='\e[0;32m'
yellow='\E[33;47m'
blue='\E[34;47m'
magenta='\E[35;47m'
cyan='\E[36;47m'
white='\E[37;47m'
endColor='\e[0m'

# Only define these codes if not running in --quiet (for crontab)
if [[ $QUIET != "1" ]]; then
	bold=$(tput bold)
	underline=$(tput sgr 0 1)
	reset=$(tput sgr0)
	purple=$(tput setaf 171)
	tan=$(tput setaf 3)
fi

#  Standard text output only to console
function console () {
	if [[ $QUIET != "1" ]]; then
		echo -e "${reset}$*${endColor}"
	fi
}

# Standard text output to console and logfile
function info () {
	if [[ $QUIET != "1" ]]; then
		echo -e "${reset}$*${endColor}"
	fi
	echo "$@" >> "${logFile}"
}

# Standard text output only to log
function log() {
	echo "$@" >> "${logFile}"
}

function input () {
	if [[ $QUIET != "1" ]]; then
		echo -e "${reset}$*${endColor}"
	fi
}

# Sectional header
function notice () {
	if [[ $QUIET != "1" ]]; then
		echo; echo -e "${green}$*${endColor}"
	fi
	echo "" >> "${logFile}"; echo "$@" >> "${logFile}"
}

function error () {
	if [[ $QUIET != "1" ]]; then
		echo -e "${red}$*${endColor}"
	else
		echo -e "$@"
	fi
	echo "ERROR: $*" >> "${logFile}"
	error_msg="$*"
	errorExit
}

function warning () {
	if [[ $QUIET != "1" ]]; then
		echo -e "${red}$*${endColor}"
	fi
	echo "WARNING: $*" >> "${logFile}"
}

function emptyLine () {
		echo ""
		echo "" >> "${logFile}"
}
