#!/usr/bin/env bash
#
# user-feedback.sh
#
###############################################################################
# Handles console feedback components
###############################################################################

# Initialize variables 
read -r pid delay spinstr temp <<< ""
echo "${pid} ${delay} ${spinstr} %{temp}" > /dev/null

# Progress spinner; we'll see if this works
function spinner() {
  if [[ "${QUIET}" != "1" ]] && [[ "${DEBUG}" != "1" ]]; then
    local pid=$1
    local delay=0.15
    # Is ther ea better way to format this thing?  It's wonky
    local spinstr='|/-\'
    tput civis;
    while [[ "$(ps a | awk '{print $1}' | grep ${pid})" ]]; do
      local temp=${spinstr#?}
      printf "Working... %c  " "$spinstr"
      local spinstr=$temp${spinstr%"$temp"}
      sleep $delay
      printf "\b\b\b\b\b\b\b\b\b\b\b\b\b\b"
    done
    printf "            \b\b\b\b\b\b\b\b\b\b\b\b"
    tput cnorm;
  fi
}

# Set up the progress bar function
function progressBar() {
  # There is a bug in here I have not been able to track down yet, so 
  # overridding set -e in this function
  # set +e
  let _progress=\(${1}*100/${2}*100\)/100
  let _done=\(${_progress}*4\)/10
  let _left=40-$_done
  _fill=$(printf "%${_done}s")
  _empty=$(printf "%${_left}s")
  printf "\rProgress : [${_fill// /#}${_empty// /-}] ${_progress}%%"
  # Switch back to strict
  # set -e
}

# Display progress bar
function showProgress() {
  if [[ "${QUIET}" != "1" ]] && [[ "${DEBUG}" != "1" ]]; then
    _start=1
    _end=100
    for number in $(seq ${_start} ${_end})
    do
    progressBar "${number}" ${_end}
    done;
    empty_line; sleep 3
  fi
}
