#!/bin/bash
#
echo "DEBUG: Loaded function _alert()"



# Set Colors
bold=$(tput bold)
underline=$(tput sgr 0 1)
reset=$(tput sgr0)
purple=$(tput setaf 171)
red=$(tput setaf 1)
green=$(tput setaf 76)
tan=$(tput setaf 3)
blue=$(tput setaf 38)

function _alert() { #my function
  if [ "${1}" = "emergency" ]; then
    local color="${bold}${red}"
  fi
  if [ "${1}" = "error" ] || [ "${1}" = "warning" ]; then
    local color="${red}"
  fi
  if [ "${1}" = "success" ]; then
    local color="${green}"
  fi
  if [ "${1}" = "debug" ]; then
    local color="${purple}"
  fi
  if [ "${1}" = "header" ]; then
    local color="${bold}""${tan}"
  fi
  if [ "${1}" = "input" ]; then
    local color="${bold}"
    printLog="0"
  fi
  if [ "${1}" = "info" ] || [ "${1}" = "notice" ]; then
    local color="" # Us terminal default color
  fi
  # Don't use colors on pipes or non-recognized terminals
  if [[ "${TERM}" != "xterm"* ]] || [ -t 1 ]; then
    color=""; reset=""
  fi

  # Print to $logFile
  if [[ ${printLog} = "true" ]] || [ "${printLog}" == "1" ]; then
    echo -e "$(date +"%m-%d-%Y %r") $(printf "[%9s]" ${1}) "${_message}"" >> $logFile;
  fi

  # Print to console when script is not 'quiet'
  ((quiet)) && return || echo -e "$(date +"%r") ${color}$(printf "[%9s]" ${1}) "${_message}"${reset}";

}

function die ()       { local _message="${@} Exiting."; echo "$(_alert emergency)"; safeExit;}
function error ()     { local _message="${@}"; echo "$(_alert error)"; }
function warning ()   { local _message="${@}"; echo "$(_alert warning)"; }
function notice ()    { local _message="${@}"; echo "$(_alert notice)"; }
function info ()      { local _message="${@}"; echo "$(_alert info)"; }
function debug ()     { local _message="${@}"; echo "$(_alert debug)"; }
function success ()   { local _message="${@}"; echo "$(_alert success)"; }
function input()      { local _message="${@}"; echo "$(_alert input)"; }
function header()     { local _message="========== ${@} ==========  "; echo "$(_alert header)"; }

# Log messages when verbose is set to "true"
verbose() {
  if [[ "${verbose}" = "true" ]] || [ ${verbose} == "1" ]; then
    debug "$@"
  fi
}