#!/usr/bin/env bash
#
# deploy.sh
#
###############################################################################
# A shell script designed to speed up and automate deployment of (primarily) 
# Wordpress websites, while integrating with third-party communication tools.
#
# https://github.com/EMRL/deploy
###############################################################################

IFS=$'\n\t'
VERSION="3.6.7-alpha.3"
EPOCH="$(date +%s)"
NOW="$(date +"%B %d, %Y")"
LAST_MONTH="$(date --date="$(date +%Y-%m-15) -1 month" +'%B')"
WEEKOF="$(date -d '7 days ago' +"%B %d, %Y")"
GASTART="$(date -d '7 days ago' "+%Y-%m-%d")"
GAEND="$(date "+%Y-%m-%d")"
DEV="${USER}@${HOSTNAME}"
APP="null"

# Set mode
set -uo pipefail

# Initialize variables 
# Startup switches
read -r APP UPGRADE SKIPUPDATE CURRENT VERBOSE QUIET STRICT DEBUG FORCE \
  SLACKTEST FUNCTIONLIST VARIABLELIST AUTOMATE EMAILTEST APPROVE \
  DENY PUBLISH DIGEST ANALYTICS ANALYTICSTEST PROJSTATS UNLOCK  \
  SSHTEST TIME UPDATEONLY POSTTEST REPORT REPAIR <<< ""
echo "${APP} ${UPGRADE} ${SKIPUPDATE} ${CURRENT} ${VERBOSE} ${QUIET} ${STRICT}  
  ${DEBUG} ${FORCE} ${SLACKTEST} ${FUNCTIONLIST} ${VARIABLELIST}
  ${AUTOMATE} ${EMAILTEST} ${APPROVE} ${DENY} ${PUBLISH} ${DIGEST}
  ${ANALYTICS} ${ANALYTICSTEST} ${PROJSTATS} ${UNLOCK} 
  ${SSHTEST} ${TIME} ${UPDATEONLY} ${POSTTEST} ${REPORT} ${REPAIR}" > /dev/null

# Temp files
read -r logFile wpFile coreFile postFile trshFile statFile urlFile <<< ""
echo "${logFile} ${wpFile} ${coreFile} ${postFile} ${trshFile} ${statFile}
  ${urlFile}" > /dev/null
# Console Colors
read -r black red green yellow blue magenta cyan white endColor bold underline \
  reset purple tan <<< ""
echo "${black} ${red} ${green} ${yellow} ${blue} ${magenta} ${cyan} ${white}
  ${endColor} ${bold} ${underline} ${reset} ${purple} ${tan}" > /dev/null

# Constants and environment variables
read -r CLEARSCREEN WORKPATH CONFIGDIR REPOHOST WPCLI SMARTCOMMIT GITSTATS \
  EMAILHTML NOPHP FIXPERMISSIONS DEVUSER DEVGROUP APACHEUSER APACHEGROUP TO \
  FROM SUBJECT EMAILERROR EMAILSUCCESS EMAILQUIT FROMDOMAIN FROMUSER \
  POSTEMAILHEAD POSTEMAILTAIL POSTTOSLACK SLACKURL SLACKERROR POSTURL NOKEY \
  PROJNAME PROJCLIENT DEVURL PRODURL REPO MASTER PRODUCTION COMMITMSG DEPLOY \
  DONOTDEPLOY TASK CHECKBRANCH ACTIVECHECK CHECKTIME GARBAGE WFCHECK ACFKEY \
  WFOFF REMOTELOG REMOTETEMPLATE LOCALHOSTPOST LOCALHOSTPATH DIGESTEMAIL DIGESTSLACK \
  DIGESTURL CLIENTLOGO REMOTEURL SCPPOST SCPUSER SCPHOST SCPHOSTPATH SCPPASS SCPCMD \
  SSHCMD LOGMSG EXPIRELOGS SERVERCHECK STASH MAILPATH REQUIREAPPROVAL ADDTIME \
  TASKUSER CLIENTID CLIENTSECRET REDIRECTURI AUTHORIZATIONCODE ACCESSTOKEN \
  REFRESHTOKEN PROFILEID ALLOWROOT SHORTEMAIL INCOGNITO \
  REPORTURL CLIENTCONTACT INCLUDEHOSTING <<< ""
echo "${CLEARSCREEN} ${WORKPATH} ${CONFIGDIR} ${REPOHOST} ${WPCLI} 
  ${SMARTCOMMIT} ${GITSTATS} ${EMAILHTML} ${NOPHP} ${FIXPERMISSIONS} ${DEVUSER} 
  ${DEVGROUP} ${APACHEUSER} ${APACHEGROUP} ${TO} ${FROM} ${SUBJECT} ${EMAILERROR} 
  ${EMAILSUCCESS} ${EMAILQUIT} ${FROMDOMAIN} ${FROMUSER} ${POSTEMAILHEAD} 
  ${POSTEMAILTAIL} ${POSTTOSLACK} ${SLACKURL} ${SLACKERROR} ${POSTURL} ${NOKEY} 
  ${PROJNAME} ${PROJCLIENT} ${DEVURL} ${PRODURL} ${REPO} ${MASTER} ${PRODUCTION} 
  ${COMMITMSG} ${DEPLOY} ${DONOTDEPLOY} ${TASK} ${CHECKBRANCH} ${ACTIVECHECK} 
  ${CHECKTIME} ${GARBAGE} ${WFCHECK} ${ACFKEY} ${WFOFF} ${REMOTELOG} ${REMOTETEMPLATE}
  ${LOCALHOSTPOST} ${LOCALHOSTPATH} ${DIGESTEMAIL} ${DIGESTSLACK} ${DIGESTURL}
  ${CLIENTLOGO} ${REMOTEURL} ${SCPPOST} ${SCPUSER} ${SCPHOST} 
  ${SCPHOSTPATH} ${SCPPASS} ${SCPCMD} ${SSHCMD} ${LOGMSG} ${EXPIRELOGS} 
  ${SERVERCHECK} ${STASH} ${MAILPATH} ${REQUIREAPPROVAL} ${ADDTIME} ${TASKUSER} 
  ${CLIENTID} ${CLIENTSECRET} ${REDIRECTURI} ${AUTHORIZATIONCODE} ${ACCESSTOKEN} 
  ${REFRESHTOKEN} ${PROFILEID} ${ALLOWROOT} 
  ${SHORTEMAIL} ${INCOGNITO} ${REPORTURL} ${CLIENTCONTACT}
  ${INCLUDEHOSTING}" > /dev/null
# Internal variables
read -r var optstring options logFile wpFile coreFile postFile trshFile statFile \
  urlFile htmlFile htmlSendmail htmlEmail clientEmail textSendmail deployPath \
  etcLocation libLocation POSTEMAIL current_branch error_msg notes \
  UPDCORE TASKLOG PCA PCB PCC PCD PLUGINS slack_icon APPRC USERRC message_state \
  COMMITURL COMMITHASH UPD1 UPD2 UPDATE gitLock AUTOMERGE MERGE EXITCODE \
  currentStash deploy_cmd deps start_branch postSendmail SLACKUSER NOCHECK \
  VIEWPORT VIEWPORTPRE LOGTITLE LOGURL TIMESTAMP STARTUP WPROOT \
  WPAPP WPSYSTEM DONOTUPDATEWP gitHistory ANALYTICSMSG digestSendmail MINAUSER \
  MINADOMAIN SSHTARGET SSHSTATUS REMOTEFILE GREETING LOGSUFFIX \
  DISABLESSHCHECK URL CODE DEPLOYPID DEPLOYTEST payload reportFile \
  TMP MONITORURL MONITORUSER MONITORPASS SERVERID \
  MONITORHOURS LATENCY UPTIME MONITORTEST MONITORAPI RELEASE RELEASENOTES \
  RELEASEURL <<< ""
echo "${var} ${optstring} ${options} ${logFile} ${wpFile} ${coreFile} ${postFile} 
  ${trshFile} ${statFile} ${urlFile} ${htmlFile} ${htmlSendmail} ${htmlEmail} 
  ${clientEmail} ${textSendmail} ${deployPath} ${etcLocation} ${libLocation} 
  ${POSTEMAIL} ${current_branch} ${error_msg} ${notes} ${UPDCORE} 
  ${TASKLOG} ${PCA} ${PCB} ${PCC} ${PCD} ${PLUGINS} ${slack_icon} ${APPRC} ${USERRC} 
  ${message_state} ${COMMITURL} ${COMMITHASH} ${UPD1} ${UPD2} ${UPDATE} ${gitLock} 
  ${AUTOMERGE} ${MERGE} ${EXITCODE} ${currentStash} ${deploy_cmd} ${deps} 
  ${start_branch} ${postSendmail} ${SLACKUSER} ${NOCHECK} ${VIEWPORT} 
  ${VIEWPORTPRE} ${LOGTITLE} ${LOGURL} ${TIMESTAMP} ${STARTUP} ${WPROOT} ${WPAPP} 
  ${WPSYSTEM} ${DONOTUPDATEWP} ${gitHistory} ${ANALYTICSMSG} 
  ${digestSendmail} ${MINAUSER} ${MINADOMAIN} ${SSHTARGET} ${SSHSTATUS} 
  ${REMOTEFILE} ${GREETING} ${LOGSUFFIX} ${DISABLESSHCHECK}
  ${URL} ${CODE} ${DEPLOYPID} ${DEPLOYTEST} ${payload} ${reportFile} 
  ${TMP} ${MONITORURL} ${MONITORUSER} ${MONITORPASS} 
  ${SERVERID} ${MONITORHOURS} ${LATENCY} ${UPTIME} ${MONITORTEST} 
  ${MONITORAPI} ${RELEASE} ${RELEASENOTES} ${RELEASEURL}" > /dev/null

# Display command options
function flags() {
  echo -n "Usage: deploy [options] [target] ...

Options:
  -F, --force            Skip all user interaction, forces 'Yes' to all actions
  -S, --skip-update      Skip any Wordpress core/plugin updates
  -u, --update           If no available Wordpress updates, halt deployment
  -U, --update-only      Deploy only Wordpresss plugin/core updates
  -P, --publish          Publish current production code to live environment
  -m, --merge            Force merge of branches
  -c, --current          Deploy a project from current working directory          
  -t, --time             Add time to project management integration
  -V, --verbose          Output more process information to screen
  -q, --quiet            Display minimal output on screen
  -h, --help             Display this help and exit
  -v, --version          Output version information and exit

Other Options:
  --automate             For unattended deployment via cron
  --approve              Approve and deploy queued code changes
  --deny                 Deny queued code changes
  --digest               Create and send weekly digest
  --report               Create a monthly activity report
  --no-check             Override active file and server checks
  --stats                Generate project statistics pages
  --strict               Any error will halt deployment completely
  --debug                Run in debug mode
  --unlock               Delete expired lock files
  --repair               Repair a deployment after key failure
  --ssh-test             Validate SSH key setup
  --email-test           Test email configuration
  --slack-test           Test Slack integration
  --post-test            Test webhook integration  
  --analytics-test       Test Google Analytics authentication
  --monitor-test         Test production server uptime and latency monitoring
  --function-list        Output a list of all functions()
  --variable-list        Output a project's declared variables 

More information at https://github.com/EMRL/deploy
"
}

# If no arguments are passed, display help
[[ $# == "0" ]] && set -- "--help"

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
    -u|--update) UPGRADE="1" ;;
    -U|--update-only) UPDATEONLY="1" ;;
    -P|--publish) PUBLISH="1" ;;
    -S|--skip-update) SKIPUPDATE="1" ;;
    -c|--current) CURRENT="1" ;;
    -v|--version) echo "$(basename "${0}") ${VERSION}"; exit ;;
    -V|--verbose) VERBOSE="1" ;;
    -q|--quiet) QUIET="1" ;;
    --strict) STRICT="1" ;;
    --debug) DEBUG="1" ;;
    -F|--force) FORCE="1" ;;
    -m|--merge) MERGE="1" ;; 
    -t|--time) TIME="1" ;;
    --approve) APPROVE="1"; FORCE="1" ;;
    --deny) DENY="1"; FORCE="1" ;;
    --digest) DIGEST="1"; FORCE="1"; QUIET="1" ;;
    --report) REPORT="1"; FORCE="1"; QUIET="1" ;;
    --automate) FORCE="1"; UPGRADE="1"; MERGE="1"; QUIET="1"; AUTOMATE="1" ;;
    --ssh-test) SSHTEST="1" ;;
    --slack-test) SLACKTEST="1" ;;
    --email-test) EMAILTEST="1" ;;
    --post-test) POSTTEST="1" ;;
    --analytics-test) ANALYTICSTEST="1" ;; 
    --monitor-test) MONITORTEST="1" ;;
    --stats) PROJSTATS="1" ;;
    --unlock) UNLOCK="1" ;;
    --repair) REPAIR="1"; FORCE="1"; STASH="TRUE"; VERBOSE="1" ;;
    --no-check) NOCHECK="1" ;;
    --function-list) FUNCTIONLIST="1"; CURRENT="1" ;; # Spoofs --current
    --variable-list) VARIABLELIST="1"; CURRENT="1" ;; # Spoofs --current
    --endopts) shift; break ;;
    *) echo "Invalid option: '$1'" 1>&2 ; exit 1 ;;
  esac
  shift
done

# Run in debug mode, if set
[[ "${DEBUG}" == "1" ]] && set -x

# Exit on empty variable, will possibly get confused by git output
[[ "${STRICT}" == "1" ]] && set -e

# Store the remaining part as arguments.
APP=("${@}") # Originally I had it like this: APP+=("${@}") I can't remember why @.@

# Check to see if the user is deploying from current working directory
if [[ "${CURRENT}" == "1" ]]; then
  WORKPATH="$(dirname "${PWD}")"
  APP="${PWD##*/}"
fi

# Get the active switches for display in logfiles
[[ "${AUTOMATE}" == "1" ]] && STARTUP="${STARTUP} --automate"
[[ "${UPGRADE}" == "1" ]] && STARTUP="${STARTUP} --update"
[[ "${APPROVE}" == "1" ]] && STARTUP="${STARTUP} --approve" #; FORCE="1"
[[ "${DENY}" == "1" ]] && STARTUP="${STARTUP} --deny" #; FORCE="1"
[[ "${PUBLISH}" == "1" ]] && STARTUP="${STARTUP} --publish"
[[ "${SKIPUPDATE}" == "1" ]] && STARTUP="${STARTUP} --skip-update"
[[ "${TIME}" == "1" ]] && STARTUP="${STARTUP} --time"
[[ "${CURRENT}" == "1" ]] && STARTUP="${STARTUP} --current"
[[ "${VERBOSE}" == "1" ]] && STARTUP="${STARTUP} --verbose"
[[ "${QUIET}" == "1" ]] && STARTUP="${STARTUP} --quiet"
[[ "${STRICT}" == "1" ]] && STARTUP="${STARTUP} --strict"
[[ "${DEBUG}" == "1" ]] && STARTUP="${STARTUP} --debug"
[[ "${FORCE}" == "1" ]] && STARTUP="${STARTUP} --force"
[[ "${MERGE}" == "1" ]] && STARTUP="${STARTUP} --merge"
[[ "${NOCHECK}" == "1" ]] && STARTUP="${STARTUP} --no-check"
[[ "${UNLOCK}" == "1" ]] && STARTUP="${STARTUP} --unlock"
[[ "${REPAIR}" == "1" ]] && STARTUP="${STARTUP} --repair"
[[ "${UPDATEONLY}" == "1" ]] && STARTUP="${STARTUP} --update-only"

# Probably not relevant but included because reasons
[[ "${SLACKTEST}" == "1" ]] && STARTUP="${STARTUP} --slack-test"
[[ "${POSTTEST}" == "1" ]] && STARTUP="${STARTUP} --post-test"
[[ "${EMAILTEST}" == "1" ]] && STARTUP="${STARTUP} --email-test"
[[ "${FUNCTIONLIST}" == "1" ]] && STARTUP="${STARTUP} --function-list"
[[ "${VARIABLELIST}" == "1" ]] && STARTUP="${STARTUP} --variable-list"

# If not trying to deploy current directory, and no repo is named in the startup command, exit
if [[ "${CURRENT}" != "1" ]] && [[ -z "${*}" ]]; then
  echo "Choose a valid project, or use the --current flag to deploy from the current directory."; exit 1
fi

# Fire up temporary log files. Consolidate this shit better someday, geez.
# 
# Crash and burn
function log_fail() {
  echo "Could not create temporary file, exiting."; exit 1
}

# Main log file
logFile="/tmp/${APP}.log-$RANDOM.log"
(umask 077 && touch "${logFile}") || log_fail
wpFile="/tmp/${APP}.wp-$RANDOM.log"; (umask 077 && touch "${wpFile}" &> /dev/null) || log_fail
coreFile="/tmp/${APP}.core-$RANDOM.log"; (umask 077 && touch "${coreFile}" &> /dev/null) || log_fail

# Start writing the logfile
echo -e "Deployment logfile for ${APP^^} - $NOW\r" >> "${logFile}"
echo -e "Launching deploy${STARTUP}\n" >> "${logFile}"

# More crappy tmp files
postFile="/tmp/${APP}.wtf-$RANDOM.log"; (umask 077 && touch "${postFile}" &> /dev/null) || log_fail
trshFile="/tmp/${APP}.trsh-$RANDOM.log"; (umask 077 && touch "${trshFile}" &> /dev/null) || log_fail
statFile="/tmp/${APP}.stat-$RANDOM.log"; (umask 077 && touch "${statFile}" &> /dev/null) || log_fail 
urlFile="/tmp/${APP}.url-$RANDOM.log"; (umask 077 && touch "${urlFile}" &> /dev/null) || log_fail
htmlFile="/tmp/${APP}.log-$RANDOM.html"; (umask 077 && touch "${htmlFile}" &> /dev/null) || log_fail
htmlEmail="/tmp/${APP}.email-$RANDOM.html"; (umask 077 && touch "${htmlEmail}" &> /dev/null) || log_fail
clientEmail="/tmp/${APP}.shortemail-$RANDOM.html"; (umask 077 && touch "${clientEmail}" &> /dev/null) || log_fail

# Path of the script; I should flip this check to make it more useful
if [ -d "/etc/deploy" ]; then
  deployPath="/etc/deploy"
else
  deployPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
fi

# Load external configuration & functions
libLocation="${deployPath}/lib/loader.sh"
etcLocation="${deployPath}/deploy.conf"

# System wide configuration files
if [[ -f "${etcLocation}" ]]; then
  # shellcheck disable=1090
  source "${etcLocation}"
else
  echo "Unable to load configuration file at ${etcLocation}, exiting."
  exit 1
fi

# Check to see if the user is deploying from current working directory
if [[ "${CURRENT}" == "1" ]]; then
  WORKPATH="$(dirname "${PWD}")"
  APP="${PWD##*/}"
fi

# If not trying to deploy current directory, and no repo is named, exit
if [[ "${CURRENT}" != "1" ]]; then
  # if [[ -z "${@}" ]]; then
  if [[ -z "${APP}" ]]; then
    echo "Choose a valid project, or use the --current flag to deploy from the current directory."
    exit 1
  else
    if [[ ! -d "${WORKPATH}/${APP}" ]]; then
      echo "${WORKPATH}/${APP} is not a valid project."
      exit 1
    fi
  fi
fi

# Load per-user configuration, if it exists
if [[ -r ~/.deployrc ]]; then
  # shellcheck disable=1090
  source ~/.deployrc; USERRC=1
fi

# Load libraries, or die
if [[ -f "${libLocation}" ]]; then
  # shellcheck disable=1090
  source "${libLocation}"
else
  echo "Unable to load libraries at ${libLocation}, exiting."
  exit 1
fi

# Function list
if [[ "${FUNCTIONLIST}" == "1" ]]; then
  compgen -A function | more; quickExit
fi

# Variable list
if [[ "${VARIABLELIST}" == "1" ]]; then
  ( set -o posix ; set ) | cat -v; quickExit
fi

# Spam all the things!
trace "Version ${VERSION}"
if [[ "${INCOGNITO}" != "TRUE" ]]; then
  trace "Running from ${deployPath}"
  trace "Loading system configuration file from ${etcLocation}"
fi

# Does a user configuration exit?
if [[ "${USERRC}" == "1" ]]; then
  if [[ "${INCOGNITO}" != "TRUE" ]]; then
    trace "Loading user configuration from ~/.deployrc"
  fi
else
  trace "User configuration not found, creating"
  cp "${deployPath}"/.deployrc ~/.deployrc
  console "User configuration file missing, creating ~/.deployrc"
  if yesno --default yes "Would you like to edit the configuration file now? [Y/n] "; then
    nano ~/.deployrc
    clear; sleep 1
    console "Loading user configuration."
    # shellcheck source=/dev/null
    source ~/.deployrc
    # quickExit
  else
    info "You can change configuration later by editing ~/.deployrc"
  fi
fi

# Load per-project configuration, if it exists
if [[ -f "${WORKPATH}/${APP}/${CONFIGDIR}/deploy.sh" ]]; then
  if [[ "${INCOGNITO}" != "TRUE" ]]; then
    trace "Loading project configuration from ${WORKPATH}/${APP}/${CONFIGDIR}/deploy.sh"
  fi
  # shellcheck disable=1090
  source "${WORKPATH}/${APP}/${CONFIGDIR}/deploy.sh"; APPRC="1"
  # Fallback to configuration file in the root directory if it exists
elif [[ -f "${WORKPATH}/${APP}/.deploy.sh" ]]; then
  if [[ "${INCOGNITO}" != "TRUE" ]]; then
    trace "Loading project configuration from ${WORKPATH}/${APP}/.deploy.sh"
  fi
  # shellcheck disable=1090
  source "${WORKPATH}/${APP}/.deploy.sh"; APPRC="1"
  # Zero out the configdir variable
  CONFIGDIR=""
elif [[ -f "${WORKPATH}/${APP}/deploy.sh" ]]; then
  if [[ "${INCOGNITO}" != "TRUE" ]]; then
    trace "Loading project configuration from ${WORKPATH}/${APP}/deploy.sh"
  fi
  # shellcheck disable=1090
  source "${WORKPATH}/${APP}/deploy.sh"; APPRC="1"
  # Zero out the configdir variable
  CONFIGDIR=""
else
  trace "No project configuration file found"
fi

# Does a project configuration exist?
#if [[ "${APPRC}" != "1" ]]; then
#  trace "No project configuration file found"
#fi

# Make sure variables are set up correctly
for var in "${REPOHOST} ${CLIENTLOGO}" "${DEVURL}" "${PRODURL}"; do
  if [[ -n "${var}" ]]; then
    if [[ "${var}" != *"http"*"://"* ]]; then
      error "The URL in your configuration ($var) must be preceded by either http:// or https:// - check your setup."
    fi
  fi
done

# Check variables for weird characters
validate_conf

# Are we using "smart" *cough* commits?
if [[ "${SMARTCOMMIT}" == "TRUE" ]]; then
  trace "Smart commits enabled"
fi

# Are any integrations setup?
if [[ "${POSTTOSLACK}" == "TRUE" ]]; then
  trace "Slack integration enabled"
fi

# Integration email
POSTEMAIL="${POSTEMAILHEAD}${TASK}${POSTEMAILTAIL}"
if [[ -n "${POSTEMAIL}" ]]; then
  if [[ "${INCOGNITO}" != "TRUE" ]]; then
    trace "Email integration enabled (${POSTEMAIL})"
  else
    trace "Email integration enabled"
  fi
fi

# Load HTML theme configuration
if [[ -f "${deployPath}/html/${HTMLTEMPLATE}/theme.conf" ]]; then
  # shellcheck disable=1090
  source "${deployPath}/html/${HTMLTEMPLATE}/theme.conf"
fi

# Remote logging?
if [[ "${REMOTELOG}" == "TRUE" ]]; then
  trace "Remote log posting enabled"
fi

# General info
if [[ "${INCOGNITO}" != "TRUE" ]]; then
  trace "Log file is ${logFile}"
  trace "Development workpath is ${WORKPATH}"
  # Are we planning on "fixing" permissions?
  if [[ "${FIXPERMISSIONS}" == "TRUE" ]]; then
    trace "Lead developer permissions are ${DEVUSER}.${DEVGROUP}"
    trace "Apache permissions are ${APACHEUSER}.${APACHEGROUP}"
  fi
fi

# Check for upcoming merge
if [[ "${AUTOMERGE}" == "TRUE" ]]; then
  MERGE="1"
  trace "Automerge is enabled"
fi

if [[ "${NOCHECK}" == "1" ]]; then
  SERVERCHECK="FALSE";
  ACTIVECHECK="FALSE"
fi

# If using --automate, force branch checking
if [[ "${AUTOMATE}" == "1" ]] || [[ "${REPAIR}" == "1" ]]; then
  CHECKBRANCH="${MASTER}";
  trace "Enforcing branch checking: ${MASTER}"
fi

trace "Current project is ${APP}"
if [[ "${INCOGNITO}" != "TRUE" ]]; then
  trace "Current user is ${DEV}"
  trace "Git lock at ${gitLock}"
fi

# Start checking for errors
# Check for publishing vs. user input
if [[ "${PUBLISH}" == "1" ]]; then
  if [[ "${FORCE}" == "1" ]] || [[ "${QUIET}" == "1" ]]; then
    error "You can not publish production code without user interaction."
  fi
fi

# If approval required, are smart commits enabled?
if [[ "${REQUIREAPPROVAL}" == "TRUE" ]] && [[ "${SMARTCOMMIT}" != "TRUE" ]]; then
  SMARTCOMMIT="TRUE"
  trace "Enabling smart commits for approval queue" 
fi

# Has this repo already been approved?
if [[ "${REQUIREAPPROVAL}" == "TRUE" ]] && [[ -f "${WORKPATH}/${APP}/.queued" ]] && [[ -f "${WORKPATH}/${APP}/.approved" ]]; then 
  APPROVE="1"; FORCE="1"
fi

# Is someone trying to approve and deny at the same time? :trollface:
if [[ "${APPROVE}" == "1" ]] && [[ "${DENY}" == "1" ]]; then
  error "The --approve and --deny switches can not be used together."
fi

# Check if a deployment is queued
if [[ "${REQUIREAPPROVAL}" == "TRUE" ]] && [[ -f "${WORKPATH}/${APP}/.queued" ]]; then
  if [[ "${APPROVE}" != "1" ]] && [[ "${DENY}" != "1" ]]; then
    queue_check
  fi
  if [[ "${DENY}" == "1" ]] || [[ -f "${WORKPATH}/${APP}/.denied" ]]; then
    deny
  fi
fi

# Check if approval is queued
if [[ ! -f "${WORKPATH}/${APP}/.queued" ]]; then
  if [[ "${APPROVE}" == "1" ]] || [[ "${DENY}" == "1" ]]; then
    if [[ "${REQUIREAPPROVAL}" != "TRUE" ]]; then
      warning "This project is not configured to require approval." 
    else  
      warning "No outstanding approval request found."
    fi
    quietExit
  fi
fi

# Disable SSH check for those that will never need it
if [[ "${NOKEY}" == "TRUE" ]]; then
  DISABLESSHCHECK="TRUE"
fi

# If user is trying to merge, make sure a second branch is configured
if [[ "${MERGE}" == "1" ]] && [[ -z "${PRODUCTION}" ]]; then
  # If using --automate, shut 'em down'
  if [[ "${AUTOMATE}" == "1" ]]; then
    error "Automated deployment requires a code merge, but a target branch is not defined."
  fi
  # If not, spit out warnings and begin walk of shame
  if [[ "${AUTOMERGE}" == "TRUE" ]]; then
    warning "This project is configured to automatically merge branches, but a target branch is not defined."
  else
    warning "You are attempting to merge branches, but a target branch is not defined."
  fi
  quietExit
fi

# Execute the deploy process
core

# Trapping stuff
trap userExit INT

# All done
safeExit
