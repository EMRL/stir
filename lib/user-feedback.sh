#!/usr/bin/env bash
#
# user-feedback.sh
#
###############################################################################
# Handles console feedback components
###############################################################################

# Initialize variables
var=(pid delay spinstr temp)
init_loop

# Progress spinner; we'll see if this works
function spinner() {
  local pid=$1
  local delay=0.15
  # Is there a better way to format this thing?  It's wonky
  local spinstr='|/-\'
  tput civis;
  while [[ "$(ps a | awk '{print $1}' | grep ${pid})" ]]; do
    if [[ "${QUIET}" != "1" ]] && [[ "${DEBUG}" != "1" ]]; then
      local temp=${spinstr#?}
      printf "Working... %c  " "$spinstr"
      local spinstr=$temp${spinstr%"$temp"}
      sleep $delay
      printf "\b\b\b\b\b\b\b\b\b\b\b\b\b\b"
    fi
  done
  printf "            \b\b\b\b\b\b\b\b\b\b\b\b"
  tput cnorm;
}

# Set up the progress bar function
function progress_bar() {
  let _progress=\(${1}*100/${2}*100\)/100
  let _done=\(${_progress}*4\)/10
  let _left=40-$_done
  _fill=$(printf "%${_done}s")
  _empty=$(printf "%${_left}s")
  if [[ "${QUIET}" != "1" ]]; then
    printf "\rProgress : [${_fill// /#}${_empty// /-}] ${_progress}%%"
  fi
}

# Display progress bar
function show_progress() {
  if [[ "${QUIET}" != "1" ]] && [[ "${DEBUG}" != "1" ]]; then
    _start=1
    _end=100
    for number in $(seq ${_start} ${_end})
    do
    progress_bar "${number}" ${_end}
    done;
    empty_line; sleep 3
  fi
}

function dot {  
  if [[ "${QUIET}" != "1" ]] && [[ "${DEBUG}" != "1" ]]; then
    if [[ "${1-default}" == "newline" ]]; then
      echo "."
    else
      echo -n "."
    fi
  fi
}

function plus {  
  if [[ "${QUIET}" != "1" ]] && [[ "${DEBUG}" != "1" ]]; then
    if [[ "${1-default}" == "newline" ]]; then
      echo "+"
    else
      echo -n "+"
    fi
  fi
}
