#!/bin/bash
#
# deploy: A simple bash script for deploying sites.
#
IFS=$'\n\t'
VERSION="3.5"
NOW=$(date +"%m/%d/%Y (%r)")
DEV=$USER"@"$HOSTNAME

# Initialize and export all startup variables so we can pass ShellCheck tests 
# as well as run in strict mode - this seems super clunky, there has to be a 
# better way!
#
# Set mode
set -uo pipefail
# Startup variables
read -r UPGRADE SKIPUPDATE CURRENT VERBOSE QUIET STRICT DEBUG FORCE \
	SLACKTEST FUNCTIONLIST VARIABLELIST AUTOMATE <<< ""
echo "${UPGRADE} ${SKIPUPDATE} ${CURRENT} ${VERBOSE} ${QUIET} ${STRICT} 	
	${DEBUG} ${FORCE} ${SLACKTEST} ${FUNCTIONLIST} ${VARIABLELIST}
	${AUTOMATE}" > /dev/null
# Temp files
read -r logFile wpFile coreFile postFile trshFile statFile urlFile <<< ""
echo "${logFile} ${wpFile} ${coreFile} ${postFile} ${trshFile} ${statFile} \
	${urlFile}" > /dev/null
# Console Colors
read -r black red green yellow blue magenta cyan white endColor bold underline \
	reset purple tan <<< ""
echo "${black} ${red} ${green} ${yellow} ${blue} ${magenta} ${cyan} ${white} \
	${endColor} ${bold} ${underline} ${reset} ${purple} ${tan}" > /dev/null
# User feedback
read -r pid delay spinstr <<< ""
echo "${pid} ${delay} ${spinstr}" > /dev/null
# Constants and environment variables
read -r CLEARSCREEN WORKPATH CONFIGDIR REPOHOST WPCLI SMARTCOMMIT GITSTATS \
	EMAILHTML NOPHP FIXPERMISSIONS DEVUSER DEVGROUP APACHEUSER APACHEGROUP TO \
	SUBJECT EMAILERROR EMAILSUCCESS EMAILQUIT FROMDOMAIN FROMUSER \
	POSTEMAILHEAD POSTEMAILTAIL POSTTOSLACK SLACKURL SLACKERROR POSTURL NOKEY \
	PROJNAME PROJCLIENT DEVURL PRODURL REPO MASTER PRODUCTION COMMITMSG DEPLOY \
	DONOTDEPLOY TASK CHECKBRANCH ACTIVECHECK CHECKTIME GARBAGE WFCHECK ACFKEY \
	WFOFF REMOTELOG POSTTOLOCALHOST LOCALHOSTPATH NOTIFYCLIENT CLIENTEMAIL \
	CLIENTLOGO REMOTEURL AUTOMATEDONLY SCPPOST SCPUSER SCPHOST SCPHOSTPATH \
	SCPPASS	LOGMSG EXPIRELOGS SERVERCHECK <<< ""
echo "${CLEARSCREEN} ${WORKPATH} ${CONFIGDIR} ${REPOHOST} ${WPCLI} 
	${SMARTCOMMIT} ${GITSTATS} ${EMAILHTML} ${NOPHP} ${FIXPERMISSIONS} ${DEVUSER} 
	${DEVGROUP} ${APACHEUSER} ${APACHEGROUP} ${TO} ${SUBJECT} ${EMAILERROR} 
	${EMAILSUCCESS} ${EMAILQUIT} ${FROMDOMAIN} ${FROMUSER} ${POSTEMAILHEAD} 
	${POSTEMAILTAIL} ${POSTTOSLACK} ${SLACKURL} ${SLACKERROR} ${POSTURL} ${NOKEY} 
	${PROJNAME} ${PROJCLIENT} ${DEVURL} ${PRODURL} ${REPO} ${MASTER} ${PRODUCTION} 
	${COMMITMSG} ${DEPLOY} ${DONOTDEPLOY} ${TASK} ${CHECKBRANCH} ${ACTIVECHECK} 
	${CHECKTIME} ${GARBAGE} ${WFCHECK} ${ACFKEY} ${WFOFF} ${REMOTELOG}
	${POSTTOLOCALHOST} ${LOCALHOSTPATH} ${NOTIFYCLIENT} ${CLIENTEMAIL}
	${CLIENTLOGO} ${REMOTEURL} ${AUTOMATEDONLY} ${SCPPOST} ${SCPUSER} ${SCPHOST} 
	${SCPHOSTPATH} ${SCPPASS} ${LOGMSG} ${EXPIRELOGS} ${SERVERCHECK}"> /dev/null
# Internal variables
read -r optstring options logFile wpFile coreFile postFile trshFile statFile \
	urlFile htmlFile htmlEmail clientEMail deployPath etcLocation libLocation \
	POSTEMAIL current_branch error_msg active_files notes UPDCORE TASKLOG PCA \
	PCB PCC PCD PLUGINS slack_icon APPRC message_state COMMITURL COMMITHASH \
	UPD1 UPD2 UPDATE gitLock AUTOMERGE MERGE EXITCODE <<< ""
echo "${optstring} ${options} ${logFile} ${wpFile} ${coreFile} ${postFile} 
	${trshFile} ${statFile} ${urlFile} ${htmlFile} ${htmlEmail} ${clientEMail} 
	${deployPath} ${etcLocation} ${libLocation} ${POSTEMAIL} ${current_branch} 
	${error_msg} ${active_files} ${notes} ${UPDCORE} ${TASKLOG} ${PCA} ${PCB} 
	${PCC} ${PCD} ${PLUGINS} ${slack_icon} ${APPRC} ${message_state} ${COMMITURL} 
	${COMMITHASH} ${UPD1} ${UPD2} ${UPDATE} ${gitLock} ${AUTOMERGE} 
	${MERGE} ${EXITCODE}" > /dev/null

# Options
function flags() {
	echo -n "Usage: deploy [options] [target] ...

Options:
  -F, --force            Skip all user interaction, forces 'Yes' to all actions
  -S, --skip-update      Skip any Wordpress core/plugin updates
  -u, --update           If no available Wordpress updates, halt deployment
  -m, --merge            Force merge of branches
  -c, --current          Deploy a project from current working directory          
  -V, --verbose          Output more process information to screen
  -q, --quiet            Display minimal output on screen
  -d, --debug            Run in debug mode
  -s, --strict           Any error will halt deployment completely
  -h, --help             Display this help and exit
  -v, --version          Output version information and exit

Other Options:
  --automate             For unattended deployment, equivalent to -Fuq 
  --slack-test           Test Slack integration
  --function-list        Output a list of all functions()
  --variable-list        Output a list of all variables used by deploy 

More information at https://github.com/EMRL/deploy
"
}

# If no arguments are passed, display help
[[ $# -eq 0 ]] && set -- "--help"

# Grab options and parse their format
option_string=h
unset options
while (($#)); do
	case $1 in
		-[!-]?*)
			for ((i=1; i < ${#1}; i++)); do
				c=${1:i:1}
				options+=("-$c")
				if [[ $option_string = *"$c:"* && ${1:i+1} ]]; then
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
while [[ ${1:-unset} = -?* ]]; do
	case $1 in
		-h|--help) flags >&2; exit ;;
		-u|--update) UPGRADE=1 ;;
		-S|--skip-update) SKIPUPDATE=1 ;;
		-c|--current) CURRENT=1 ;;
		-v|--version) echo "$(basename "${0}") ${VERSION}"; exit ;;
		-V|--verbose) VERBOSE=1 ;;
		-q|--quiet) QUIET=1 ;;
		-s|--strict) STRICT=1 ;;
		-d|--debug) DEBUG=1 ;;
		-F|--force) FORCE=1 ;;
		-m|--merge) MERGE=1 ;; 
		--automate) FORCE=1; UPGRADE=1; MERGE=1; QUIET=1; AUTOMATE=1 ;;
		--slack-test) SLACKTEST=1 ;;
		--function-list) FUNCTIONLIST=1; APP="null";;
		--variable-list) VARIABLELIST=1; APP="null";;
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
APP+=("${@}")

# Check to see if the user is deploying from current working directory
if [ "${CURRENT}" == "1" ]; then
	WORKPATH="$(dirname "${PWD}")"
	APP="${PWD##*/}"
fi

# If not trying to deploy current directory, and no repo is named, exit
if [ -z "${@}" ] && [ "${CURRENT}" != "1" ]; then
	echo "Choose a valid project, or use the --current flag to deploy from the current directory."
	exit 1
fi

# Fire up temporary log files. Consolidate this shit better someday, geez.
# 
# Main log file
logFile="/tmp/$APP.log-$RANDOM.log"
(umask 077 && touch "${logFile}") || {
	echo "Could not create temporary file, exiting."
	exit 1
}
wpFile="/tmp/$APP.wp-$RANDOM.log"
(umask 077 && touch "${wpFile}") || {
	echo "Could not create temporary file, exiting."
	exit 1
}
coreFile="/tmp/$APP.core-$RANDOM.log"
(umask 077 && touch "${coreFile}") || {
	echo "Could not create temporary file, exiting."
	exit 1
}
# WTF IS THIS
echo -e "Deployment logfile for ${APP^^} - $NOW\r\r" >> "${logFile}"
postFile="/tmp/$APP.wtf-$RANDOM.log"
(umask 077 && touch "${postFile}") || {
	echo "Could not create temporary file, exiting."
	exit 1
}
# Logfile for random trash, might go away
trshFile="/tmp/$APP.trsh-$RANDOM.log"
(umask 077 && touch "${trshFile}") || {
	echo "Could not create temporary file, exiting."
	exit 1
}
# Stat file, prolly will go away as well
statFile="/tmp/$APP.stat-$RANDOM.log"
(umask 077 && touch "${statFile}") || {
	echo "Could not create temporary file, exiting."
	exit 1
}
# Short URL temp file
urlFile="/tmp/$APP.url-$RANDOM.log"
(umask 077 && touch "${urlFile}") || {
	echo "Could not create temporary file, exiting."
	exit 1
}

# HTML log temp file
htmlFile="/tmp/$APP.log-$RANDOM.html"
(umask 077 && touch "${htmlFile}") || {
	echo "Could not create temporary file, exiting."
	exit 1
}

# HTML log temp file
htmlEmail="/tmp/$APP.email-$RANDOM.html"
(umask 077 && touch "${htmlEmail}") || {
	echo "Could not create temporary file, exiting."
	exit 1
}

# HTML log temp file
clientEmail="/tmp/$APP.shortemail-$RANDOM.html"
(umask 077 && touch "${clientEmail}") || {
	echo "Could not create temporary file, exiting."
	exit 1
}

# Path of the script; I should flip this check to make it more useful
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
	# shellcheck disable=1090
	source "${etcLocation}"
else
	echo "Unable to load configuration file at ${etcLocation}, exiting."
	exit 1
fi

# Check to see if the user is deploying from current working directory
if [ "${CURRENT}" == "1" ]; then
	WORKPATH="$(dirname "${PWD}")"
	APP="${PWD##*/}"
fi

# Load per-user configuration, if it exists
if [ -r ~/.deployrc ]; then
	# shellcheck disable=1090
	source ~/.deployrc; USERRC=1
fi

# Load per-project configuration, if it exists
if [ -r "${WORKPATH}/${APP}/config/deploy.sh" ]; then
	# shellcheck disable=1090
	source "${WORKPATH}/${APP}/${CONFIGDIR}/deploy.sh"; APPRC=1
fi

# Load libraries, or die
if [ -f "${libLocation}" ]; then
	# shellcheck disable=1090
	source "${libLocation}"
else
	echo "Unable to load libraries at ${libLocation}, exiting."
	exit 1
fi

# Function list
if [ "${FUNCTIONLIST}" == "1" ]; then
	compgen -A function | more; quickExit
	#compgen -A function > /tmp/func.list
	#tr '\n' ' ' < /tmp/func.list;  echo
	#quickExit
fi

# Variable list
# if [ "${VARIABLELIST}" == "1" ]; then
#	( set -o posix ; set ) | more; quickExit
# fi

# Spam all the things!
trace "Version ${VERSION}"
trace "Running from ${deployPath}"
trace "Loading system configuration file from ${etcLocation}"

# Does a user configuration exit?
if [ "${USERRC}" == "1" ]; then
	trace "Loading user configuration from ~/.deployrc"
else
	trace "User configuration not found, creating."
	cp "${deployPath}"/.deployrc ~/.deployrc
	console "User configuration file missing, creating ~/.deployrc"
	if yesno --default yes "Would you like to edit the configuration file now? [Y/n] "; then
		nano ~/.deployrc
		clear; sleep 1
		console "Loading user configuration."
		source ~/.deployrc
		# quickExit
	else
		info "You can change configuration later by editing ~/.deployrc"
	fi
fi

# Does a project configuration exist?
if [ "${APPRC}" == "1" ]; then
	trace "Loading project configuration from ${WORKPATH}/${APP}/${CONFIGDIR}/deploy.sh"
else
	trace "No project config file found"
fi

# Are we using "smart" *cough* commits?
if [ "${SMARTCOMMIT}" == "TRUE" ]; then
	trace "Smart commits are enabled"
fi

# Are any integrations setup?
if [ "${POSTTOSLACK}" == "TRUE" ]; then
	trace "Slack integration enabled"
fi

POSTEMAIL="${POSTEMAILHEAD}${TASK}${POSTEMAILTAIL}"
if [[ -n "${POSTEMAIL}" ]]; then
	trace "Email integration enabled (${POSTEMAIL})"
fi

# Remote logging?
if [ "${REMOTELOG}" == "TRUE" ]; then
	trace "Remote log posting enabled"
fi

# General info
trace "Log file is ${logFile}"
trace "Development workpath is ${WORKPATH}"

# Are we planning on "fixing" permissions?
if [ "${FIXPERMISSIONS}" == "TRUE" ]; then
	trace "Lead developer permissions are ${DEVUSER}.${DEVGROUP}"
	trace "Apache permissions are ${APACHEUSER}.${APACHEGROUP}"
fi

# Check for upcoming merge
if [ "${AUTOMERGE}" == "TRUE" ]; then
	MERGE="1"
	trace "Automerge is enabled"
fi

trace "Current project is ${APP}"
trace "Current user is ${DEV}"
trace "Git lock at ${gitLock}"

# Setup the core application
function appDeploy() {
	gitStart		# Check for a valid git project and get set up
	lock			# Create lock file
	go				# Start a deployment work session
	server_check	# Check that servers are up and running
	permFix			# Fix permissions
	gitChkMstr		# Checkout master branch
	gitGarbage		# If needed, clean up the trash
	preDeploy		# Get the status
	wpPkg			# Run Wordpress upgrades if needed
	pkgMgr			# Run node package management, or grunt
	gitStatus		# Make sure there's anything here to commit
	gitStage		# Stage files
	gitCommit		# Commit, with message
	gitPushMstr		# Push master to Bit Bucket
	gitChkProd		# Checkout production branch
	gitMerge		# Merge master into production
	gitPushProd		# Push production to Bit Bucket
	gitChkMstr		# Checkout master once again  
	pkgDeploy		# Deploy project to live server   
}

# Trapping stuff
trap userExit INT

# Execute the deploy process
appDeploy

# All done
safeExit
