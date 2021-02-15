#!/bin/bash
#
# loader.sh
#
###############################################################################
# A sub-wrapper for loading external functions
###############################################################################

# Save current contents of the terminal
if [[ "${CLEAR_SCREEN}" == "TRUE" ]]; then
  if [[ "${QUIET}" != "1" ]] && [[ "${VERBOSE}" != "TRUE" ]]; then
    tput smcup; clear
  fi
fi

if [[ "${FORCE}" != "1" ]] && [[ "${QUIET}" = "1" ]]; then
  echo "To use the --quiet flag, you must also use --force."; exit 1
fi

###############################################################################
# trace()
#   Outputs timestamped, verbose info to both console and log files
#
# Arguments:
#   status      Will place the next trace output on the same line, e.g.
#               [trace 1]Checking database... [trace 2]OK will render 
#               Checking database... OK in the logs
#   notime      Output trace with no timestamp, generally used after a 
#               `trace status "blahblah"`  
###############################################################################      
function trace() {
  if [[ "${VERBOSE}" == "TRUE" ]] && [[ "${QUIET}" != "1" ]]; then
    TIMESTAMP="$(date '+%H:%M:%S')"
    if [[ "${1}" == "status" ]]; then
      echo -e -n "$(tput setaf 3)${TIMESTAMP}$(tput sgr0) ${2}"
      echo -e -n "${TIMESTAMP} ${2}" >> "${log_file}"
    elif [[ "${1}" == "notime" ]]; then
      echo -e "${2}"
      echo "${2}" >> "${log_file}"
    else
      echo -e "$(tput setaf 3)${TIMESTAMP}$(tput sgr0) $*"
      echo "${TIMESTAMP} $*" >> "${log_file}"
    fi
  else
    TIMESTAMP="$(date '+%H:%M:%S')"
    if [[ "${1}" == "status" ]]; then
      echo -e -n "${TIMESTAMP} ${2}" >> "${log_file}"
    elif [[ "${1}" == "notime" ]]; then
      echo "${2}" >> "${log_file}"
    else
      echo "${TIMESTAMP} $*" >> "${log_file}"
    fi
  fi
}

# Source everything in /lib
SOURCE="${BASH_SOURCE[0]}"
while [[ -h "${SOURCE}" ]]; do 
  DIR="$( cd -P "$( dirname "${SOURCE}" )" && pwd )"
  SOURCE="$(readlink "${SOURCE}")"
  [[ "${SOURCE}" != /* ]] && SOURCE="${DIR}/${SOURCE}"
done

SOURCEPATH="$( cd -P "$( dirname "${SOURCE}" )" && pwd )"

if [[ ! -d "${SOURCEPATH}" ]]; then
  echo "Failed to find library files expected in: ${SOURCEPATH}"; exit 1
fi
for LIBRARIES in "${SOURCEPATH}"/*.sh
do
  if [[ -e "${LIBRARIES}" ]]; then
    # Don't source yourself, silly script
    if [[ "${LIBRARIES}" == *"loader.sh"* ]]; then
      continue
    fi
    # shellcheck disable=1090
    source "${LIBRARIES}"
  fi
done
