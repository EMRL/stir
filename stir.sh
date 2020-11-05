#!/usr/bin/env bash
#
# stir.sh
#
###############################################################################
# A shell script designed to speed up and automate management and deployment of
# (primarily) Wordpress websites, while integrating with third-party 
# communication tools.
#
# https://github.com/EMRL/stir
###############################################################################

IFS=$'\n\t'
VERSION="3.8.2-dev"
EPOCH="$(date +%s)"
NOW="$(date +"%B %d, %Y")"
last_month="$(date --date="$(date +%Y-%m-15) -1 month" +'%B')"
WEEKOF="$(date -d '7 days ago' +"%B %d, %Y")"
GASTART="$(date -d '7 days ago' "+%Y-%m-%d")"
GAEND="$(date "+%Y-%m-%d")"
DEV="${USER}@${HOSTNAME}"
APP="null"

# Set mode
set -uo pipefail

# Variable init loop
function init_loop {
  for i in "${var[@]}" ; do
    read -r "${i}" <<< ""
    echo "${i}" > /dev/null
  done
}

# Startup switches
function init_startup() {
  var=(APP UPGRADE SKIPUPDATE CURRENT VERBOSE QUIET STRICT DEBUG FORCE \
    SLACKTEST FUNCTION_LIST VARIABLE_LIST AUTOMATE EMAILTEST APPROVE \
    DENY PUBLISH DIGEST ANALYTICS ANALYTICSTEST BUILD PROJSTATS UNLOCK  \
    SSHTEST TIME UPDATEONLY test_webhook REPORT REPAIR CREATE_INVOICE SCAN \
    CHECK_BACKUP APP_PATH EXTENDED_HELP RESET PREPARE_WITH_RESET \
    SHOW_SETTINGS UNIT_TEST test_bugsnag UPDATE_ACF DEBUG_TO_FILE)
  init_loop
}

# Temp files
function init_temp() {
  var=(log_file wp_file core_file post_file trash_file scan_file stat_file \
    url_file)
  init_loop
}

# Console colors
function init_color() {
  var=(black red green yellow blue magenta cyan white endColor bold \
  underline reset purple tan)
  init_loop
}

# Constants and environment variables
function init_env() {
  var=(CLEARSCREEN WORKPATH CONFIGDIR CONFIG_BACKUP REPOHOST SMARTCOMMIT \
  GITSTATS EMAILHTML NOPHP TO FROM SUBJECT EMAILERROR EMAILSUCCESS EMAILQUIT \
  FROMDOMAIN FROMUSER POSTEMAILHEAD POSTEMAILTAIL POSTTOSLACK SLACKURL \
  SLACKERROR POSTURL NOKEY PROJNAME PROJCLIENT DEVURL PRODURL REPO MASTER \
  STAGING PRODUCTION COMMITMSG DEPLOY DONOTDEPLOY TASK CHECKBRANCH \
  ACTIVECHECK CHECKTIME GARBAGE WFCHECK ACFKEY ACF_LOCK WFOFF REMOTELOG \
  REMOTETEMPLATE LOCALHOSTPOST LOCALHOSTPATH DIGESTEMAIL DIGESTSLACK \
  DIGESTURL CLIENTLOGO REMOTEURL SCPPOST SCPUSER SCPHOST SCPHOSTPATH \
  SCPHOSTPORT SCPPASS SCPCMD SSHCMD LOGMSG EXPIRELOGS SERVERCHECK STASH \
  REQUIREAPPROVAL ADDTIME SCPPORT TASKUSER CLIENTID CLIENTSECRET \
  REDIRECTURI AUTHORIZATIONCODE ACCESSTOKEN REFRESHTOKEN PROFILEID ALLOWROOT \
  SHORTEMAIL INCOGNITO REPORTURL CLIENTCONTACT INCLUDEHOSTING GLOBAL_VERSION \
  USER_VERSION PROJECT_VERSION TERSE NOTIFYCLIENT HTMLTEMPLATE PREPARE \
  PRODUCTION_DEPLOY_HOST PRODUCTION_DEPLOY_PATH PREPARE_CONFIG \
  GRAVITY_FORMS_LICENSE NEWS_URL BUGSNAG_AUTH USE_SMTP INCLUDE_DETAILS)
  init_loop
}

# Internal variables
function init_internal() {
  var=(optstring options log_file wp_file core_file post_file trash_file stat_file \
  url_file html_file htmlSendmail html_email client_email textSendmail stir_path \
  etc_path lib_path POSTEMAIL current_branch error_msg notes \
  UPDCORE TASKLOG PCA PCB PCC PCD PLUGINS slack_icon APPRC USERRC message_state \
  COMMITURL COMMITHASH UPD1 UPD2 UPDATE git_lock AUTOMERGE MERGE EXITCODE \
  current_stash deploy_cmd deps start_branch postSendmail SLACKUSER NOCHECK \
  VIEWPORT VIEWPORTPRE LOGTITLE LOGURL TIMESTAMP STARTUP WPROOT \
  WPAPP WPSYSTEM DONOTUPDATEWP gitHistory digest_payload MINAUSER \
  MINADOMAIN SSHTARGET SSHSTATUS REMOTEFILE  LOGSUFFIX \
  DISABLESSHCHECK URL CODE DEPLOYPID DEPLOYTEST payload reportFile \
  TMP MONITORURL MONITORUSER MONITORPASS SERVERID \
  MONITORHOURS LATENCY UPTIME MONITORTEST MONITORAPI)
  init_loop
}

function init_theme() {
  var=(THEME_MODE DEFAULTC PRIMARYC SECONDARYC SUCCESSC INFOC WARNINGC \
  DANGERC LOGC LOGBC)
  init_loop
}

# Initialize all variables we'll need before loading external functions
init_startup
init_temp
init_color
init_env
init_internal
init_theme

###############################################################################
# temp_files()
#   A function to create temporary files
#
# Arguments:
#   create    Create a new set of temporary files and directories
#   remove    Remove existing temporary files and directories
###############################################################################
function temp_files() {
  if [[ -z "${1}" ]]; then
    exit 78
  else
  # Setup tempfile list
  file=(trash_file post_file stat_file scan_file scan_html wp_file \
    url_file html_file html_email client_email core_file stat_dir avatar_dir \
    stats log_file)

    # Start the loop
    if [[ "${1}" == "remove" ]]; then
      for i in "${file[@]}" ; do
        var="${i}"
        if [[ -f "${!i:-}" ]] || [[ -d "${!i:-}" ]]; then
          rm -rf "${!i:-}"
        fi
      done
    elif [[ "${1}" == "create" ]]; then
      for i in "${file[@]}" ; do
        if [[ "${i}" != *"_dir"* ]]; then
          var="/tmp/${APP}.${i}-${RANDOM}.log"; (umask 077 && touch "${var}" &> /dev/null) || log_fail ${var}
        else
          var="/tmp/${APP}.${i}-${RANDOM}"; (umask 077 && mkdir "${var}" &> /dev/null) || log_fail ${var}
        fi
        read -r "${i}" <<< "${var}"
      done
    fi
  fi
}

function log_fail() {
  echo "Could not create temporary file (${1}), exiting."; exit 2
}

# Trap ctrl-c exits; someday I'll do this better 
trap ctrl_c INT

# Function to try and cleanup after a user exit, even when external function
# libraries may not be loaded
function ctrl_c() {
  if type quiet_exit &>/dev/null; then
    quiet_exit
  else
    temp_files remove
  fi
}

# Display command options
function flags() {
  echo -n "Usage: stir [options] [target] ...

Options:
  -F, --force            Skip all user interaction, forces 'Yes' to all actions
  -S, --skip-update      Skip any Wordpress core/plugin updates
  -u, --update           If no available Wordpress updates, halt deployment
  -U, --update-only      Deploy only Wordpresss plugin/core updates
  -D, --deploy           Deploy current production code to live environment
  -m, --merge            Force merge of branches
  -c, --current          Deploy a project from current directory          
  -t, --time             Add time to project management integration
  -p, --prepare          Clone and setup local Wordpress project
  -V, --verbose          Output more process information to screen
  -q, --quiet            Display minimal output on screen
  -v, --version          Output version information and exit
  -h, --help             Display this help and exit
  -H, --more-help        Display extended help and exit
"

  if [[ "${EXTENDED_HELP}" == "1" ]]; then
    echo -n "
Other Options:
  --automate             For unattended execution via cron
  --build                Build project assets
  --prepare              Prepare project
  --reset                Resets local project files
  --prepare-with-reset   Reset and prepare project
  --digest               Create and send weekly digest
  --report               Create a monthly activity report
  --no-check             Override active file and server checks
  --stats                Generate project statistics pages
  --invoice              Create an invoice
  --strict               Any error will halt deployment completely
  --debug                Run in debug mode
  --debug-to-file        Save debug output to a file
  --unlock               Delete expired lock files
  --repair               Repair a deployment after merge failure
  --scan                 Scan production hosts for malware issues
  --update-acf           Force an update or reinstall of ACF Pro
  --test-ssh             Validate SSH key setup
  --test-email           Test email configuration
  --test-slack           Test Slack integration
  --test-webhook         Test webhook integration  
  --test-analytics       Test Google Analytics authentication
  --test-monitor         Test production server uptime and latency monitoring
  --test-bugsnag         Test Bugsnag integration
  --show-settings        Display current global and project settings
  --function-list        Output a list of all functions()
  --variable-list        Output a project's declared variables
"
  else
    echo -n "
Try 'stir -H' for extended help options"  
  fi


  echo -n "
More information at https://github.com/EMRL/stir
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
    -H|--more-help) EXTENDED_HELP="1"; flags >&2; exit ;;
    -u|--update) UPGRADE="1" ;;
    -U|--update-only) UPDATEONLY="1" ;;
    -D|--deploy) PUBLISH="1" ;;
    -S|--skip-update|--skip-updates) SKIPUPDATE="1" ;;
    -c|--current) CURRENT="1" ;;
    -v|--version) echo "$(basename "${0}") ${VERSION}"; exit ;;
    -V|--verbose) VERBOSE="1" ;;
    -q|--quiet) QUIET="1" ;;
    --strict) STRICT="1" ;;
    --debug) DEBUG="1" ;;
    --debug-to-file) DEBUG_TO_FILE="1" ;;
    -F|--force) FORCE="1" ;;
    -m|--merge) MERGE="1" ;; 
    -t|--time) TIME="1" ;;
    --approve) APPROVE="1"; FORCE="1" ;;
    --deny) DENY="1"; FORCE="1" ;;
    -p|--prepare) PREPARE="1" ;;
    --reset) RESET="1" ;;
     --prepare-with-reset) PREPARE_WITH_RESET="1"; PREPARE="1" ;;
    --digest) DIGEST="1"; FORCE="1" ;;
    --report) REPORT="1"; FORCE="1"; QUIET="1" ;;
    --automate) FORCE="1"; UPGRADE="1"; QUIET="1"; MERGE="1"; AUTOMATE="1" ;;
    --update-acf) UPDATE_ACF="1" ;;
    --test-ssh) SSHTEST="1" ;;
    --test-slack) SLACKTEST="1" ;;
    --test-email) EMAILTEST="1" ;;
    --test-webhook) test_webhook="1" ;;
    --test-analytics) ANALYTICSTEST="1" ;; 
    --test-monitor) MONITORTEST="1" ;;
    --test-bugsnag) test_bugsnag="1" ;;
    --stats) PROJSTATS="1" ;;
    --build) BUILD="1"; NOCHECK="1"; FORCE="1" ;;
    --invoice) CREATE_INVOICE="1"; FORCE="1" ;;
    --unlock) UNLOCK="1" ;;
    --repair) REPAIR="1"; FORCE="1"; STASH="TRUE"; VERBOSE="TRUE" ;;
    --scan) SCAN="1" ;;
    --no-check) NOCHECK="1" ;;
    --show-settings) SHOW_SETTINGS="1" ;;
    --function-list) FUNCTION_LIST="1"; CURRENT="1" ;; # Spoofs --current
    --variable-list) VARIABLE_LIST="1"; CURRENT="1" ;; # Spoofs --current
    --unit-test) UNIT_TEST="1" ;;
    --endopts) shift; break ;;
    *) echo "Invalid option: '$1'" 1>&2 ; exit 1 ;;
  esac
  shift
done

# Run in debug mode, if set
if [[ "${DEBUG_TO_FILE}" == "1" ]]; then
  (umask 077 && touch debug.log &> /dev/null) || log_fail debug.log
  exec 19>debug.log
  BASH_XTRACEFD=19
  set -x
else
  [[ "${DEBUG}" == "1" ]] && set -x
fi

# Exit on empty variable, will possibly get confused by git output
[[ "${STRICT}" == "1" ]] && set -e

# Store the remaining part as arguments.
APP=("${@}") # Originally I had it like this: APP+=("${@}") I can't remember why @.@

# Check to see if the user is deploying from current working directory
if [[ "${CURRENT}" == "1" ]]; then
  WORKPATH="$(dirname "${PWD}")"
  APP="${PWD##*/}"
fi

# Get the active switches for display in log_files
[[ "${AUTOMATE}" == "1" ]] && STARTUP="${STARTUP} --automate"
[[ "${UPGRADE}" == "1" ]] && STARTUP="${STARTUP} --update"
[[ "${APPROVE}" == "1" ]] && STARTUP="${STARTUP} --approve" #; FORCE="1"
[[ "${DENY}" == "1" ]] && STARTUP="${STARTUP} --deny" #; FORCE="1"
[[ "${PUBLISH}" == "1" ]] && STARTUP="${STARTUP} --publish"
[[ "${SKIPUPDATE}" == "1" ]] && STARTUP="${STARTUP} --skip-update"
[[ "${TIME}" == "1" ]] && STARTUP="${STARTUP} --time"
[[ "${CURRENT}" == "1" ]] && STARTUP="${STARTUP} --current"
[[ "${VERBOSE}" == "TRUE" ]] && STARTUP="${STARTUP} --verbose"
[[ "${QUIET}" == "1" ]] && STARTUP="${STARTUP} --quiet"
[[ "${STRICT}" == "1" ]] && STARTUP="${STARTUP} --strict"
[[ "${DEBUG}" == "1" ]] && STARTUP="${STARTUP} --debug"
[[ "${FORCE}" == "1" ]] && STARTUP="${STARTUP} --force"
[[ "${DEBUG_TO_FILE}" == "1" ]] && STARTUP="${STARTUP} --debug-to-file"
[[ "${MERGE}" == "1" ]] && STARTUP="${STARTUP} --merge"
[[ "${NOCHECK}" == "1" ]] && STARTUP="${STARTUP} --no-check"
[[ "${UNLOCK}" == "1" ]] && STARTUP="${STARTUP} --unlock"
[[ "${REPAIR}" == "1" ]] && STARTUP="${STARTUP} --repair"
[[ "${UPDATEONLY}" == "1" ]] && STARTUP="${STARTUP} --update-only"

# Probably not relevant but included because reasons
[[ "${SLACKTEST}" == "1" ]] && STARTUP="${STARTUP} --slack-test"
[[ "${test_webhook}" == "1" ]] && STARTUP="${STARTUP} --post-test"
[[ "${EMAILTEST}" == "1" ]] && STARTUP="${STARTUP} --email-test"
[[ "${FUNCTION_LIST}" == "1" ]] && STARTUP="${STARTUP} --function-list"
[[ "${VARIABLE_LIST}" == "1" ]] && STARTUP="${STARTUP} --variable-list"

# If not trying to deploy current directory, and no repo is named in the startup command, exit
if [[ "${CURRENT}" != "1" ]] && [[ -z "${*}" ]]; then
  echo "Choose a valid project, or use the --current flag to deploy from the current directory."; exit 1
fi

# Path of the script; I should flip this check to make it more useful
if [ -d "/etc/stir" ]; then
  stir_path="/etc/stir"
else
  stir_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
fi

# Load external configuration & functions
lib_path="${stir_path}/lib/loader.sh"

if [[ -r "${stir_path}/global.conf" ]]; then
  etc_path="${stir_path}/global.conf"
else
  etc_path="${stir_path}/etc/global.conf"
fi

# System wide configuration files
if [[ -f "${etc_path}" ]]; then
  # shellcheck disable=1090
  source "${etc_path}"
else
  echo "Unable to load configuration file at ${etc_path}, exiting."
  exit 12
fi

# If global.conf appears empty, launch configuration options
if [[ -z "#{WORKPATH}" ]]; then
  configure_global
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
    echo "Choose a valid project, or use the --current flag to work in the current directory."
    exit 13
  else
    if [[ ! -d "${WORKPATH}/${APP}" ]]; then
      echo "${WORKPATH}/${APP} is not a valid project."
      exit 17
    fi
  fi
fi

# Load per-user configuration, if it exists
if [[ -r ~/.stirrc ]]; then
  # shellcheck disable=1090
  source ~/.stirrc; USERRC="1"
fi

# Load libraries, or die
if [[ -f "${lib_path}" ]]; then
  # shellcheck disable=1090
  source "${lib_path}"
else
  echo "Unable to load libraries at ${lib_path}, exiting."
  exit 19
fi

# Create temporary files
temp_files create

# Fire up temporary log files. Consolidate this shit better someday, geez.
# Main log file
#log_file="/tmp/${APP}.log-$RANDOM.log"
#(umask 077 && touch "${log_file}") || log_fail
#wp_file="/tmp/${APP}.wp-$RANDOM.log"; (umask 077 && touch "${wp_file}" &> /dev/null) || log_fail
#core_file="/tmp/${APP}.core-$RANDOM.log"; (umask 077 && touch "${core_file}" &> /dev/null) || log_fail

# Start writing the log_file
echo -e "Activity log_file for ${APP^^} - ${NOW}\r" >> "${log_file}"
echo -e "Launching stir${STARTUP}\n" >> "${log_file}"

# Function list
if [[ "${FUNCTION_LIST}" == "1" ]]; then
  compgen -A function | more; quiet_exit
fi

# Variable list
if [[ "${VARIABLE_LIST}" == "1" ]]; then
  VERBOSE="FALSE"; ( set -o posix ; set ) | cat -v; quiet_exit
fi

# Do we need to be quiet?
if [[ "${SHOW_SETTINGS}" == "1" ]]; then
  VERBOSE="FALSE"
fi

# Spam all the things!
trace "Version ${VERSION}"
if [[ "${INCOGNITO}" != "TRUE" ]]; then
  trace "Running from ${stir_path}"
  trace "Loading system configuration file from ${etc_path}"
fi

# Does a user configuration exit?
if [[ "${USERRC}" != "1" ]]; then
  trace "User configuration not found, creating"
  if [[ -r "${stir_path}/stir-user.rc" ]]; then
    cp "${stir_path}"/stir-user.rc ~/.stirrc
  elif [[ -r "${stir_path}/etc/stir-user.rc" ]]; then
    cp "${stir_path}"/etc/stir-user.rc ~/.stirrc
  fi
  console "User configuration file missing, creating ~/.stirrc"
  if yesno --default yes "Would you like to edit the configuration file now? [Y/n] "; then
    configure_user; sleep 1
    console "Loading user configuration."
    # shellcheck source=/dev/null
    source ~/.stirrc
    # quiet_exit
  else
    info "You can change configuration later by editing ~/.stirrc"
    clear_user
  fi
fi

# Load per-project configuration, if it exists
if [[ -f "${WORKPATH}/${APP}/.stir.sh" ]]; then
  if [[ "${INCOGNITO}" != "TRUE" ]]; then
    trace "Loading project configuration from ${WORKPATH}/${APP}/.stir.sh"
  fi
  project_config="${WORKPATH}/${APP}/.stir.sh"
  # Zero out the global configdir variable
  CONFIGDIR=""
else
  trace "No project configuration file found"
fi

if [[ -n "${project_config}" ]]; then
  # shellcheck disable=1090 
  source "${project_config}"
  APPRC="1"
else
  # Make sure app directory is writable
  if [[ -w "${WORKPATH}/${APP}" ]]; then
    empty_line; info "Project configuration not found, creating."; sleep 2
    cp "${stir_path}"/stir-project.sh "${WORKPATH}/${APP}/.stir.sh"
    APPRC="${WORKPATH}/${APP}/.stir.sh"
    if [[ -x "$(command -v nano)" ]]; then
      if yesno --default yes "Would you like to edit the configuration file now? [Y/n] "; then
        nano "${APPRC}"
        clear; sleep 1
      fi
    fi
    info "You can change configuration later by editing ${APPRC}"
  fi
  source "${APPRC}"
fi

# Validate configuration setings
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
if [[ -f "${stir_path}/html/${HTMLTEMPLATE}/theme.conf" ]]; then
  # shellcheck disable=1090
  source "${stir_path}/html/${HTMLTEMPLATE}/theme.conf"

  # Lowercase dashboard class is better form
  if [[ -n "${THEME_MODE}" ]]; then
    THEME_MODE="$(echo ${THEME_MODE} | awk '{print tolower($0)}')"
  fi
fi

# Remote logging?
if [[ "${REMOTELOG}" == "TRUE" ]]; then
  trace "Remote log posting enabled"
fi

# General info
if [[ "${INCOGNITO}" != "TRUE" ]]; then
  trace "Log file is ${log_file}"
  trace "Project workpath is ${WORKPATH}"
fi

# Check for upcoming merge
if [[ "${AUTOMERGE}" == "TRUE" ]]; then
  MERGE="1"
  trace "Automerge is enabled"
fi

# If using --automate, force branch checking
if [[ "${AUTOMATE}" == "1" ]] || [[ "${REPAIR}" == "1" ]]; then
  CHECKBRANCH="${MASTER}";
  trace "Enforcing branch checking: ${MASTER}"
fi

trace "Current project is ${APP}"
if [[ "${INCOGNITO}" != "TRUE" ]]; then
  trace "Current user is ${DEV}"
  # trace "Git lock at ${git_lock}"
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
    quiet_exit
  fi
fi

# Disable SSH check for those that will never need it
if [[ "${NOKEY}" == "TRUE" ]]; then
  DISABLESSHCHECK="TRUE"
fi

# If user is trying to merge, make sure a second branch is configured
if [[ "${MERGE}" == "1" ]]; then
  if [[ -n "${PRODUCTION}" ]] || [[ -n "${STAGING}" ]]; then
    # Do nothing
    sleep 1
  else
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
    quiet_exit
  fi
fi

# Set app path
APP_PATH="${WORKPATH}/${APP}"

if [[ -f "${APP_PATH}/.donotstir" ]] || [[ -f "${APP_PATH}/.shaken" ]]; then
  DONOTDEPLOY="TRUE"
fi

# Execute the main application
main

# All done
clean_exit
