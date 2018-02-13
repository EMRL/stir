#!/bin/bash
#
# loader.sh
#
###############################################################################
# A sub-wrapper for loading external functions
###############################################################################

# Save current contents of the terminal
if [[ "${CLEARSCREEN}" == "TRUE" ]]; then
  if [[ "${QUIET}" != "1" ]] && [[ "${VERBOSE}" != "TRUE" ]]; then
    tput smcup; clear
  fi
fi

if [[ "${FORCE}" != "1" ]] && [[ "${QUIET}" = "1" ]]; then
  echo "To deploy using the --quiet flag, you must also use --force."; exit 1
fi

# Creating this function first, so verbose output option is usable early
function trace() {
  if [[ "${VERBOSE}" == "TRUE" ]]; then
    TIMESTAMP="$(date '+%H:%M:%S')"
    echo -e "$(tput setaf 3)${TIMESTAMP}$(tput sgr0) $*"
    echo "${TIMESTAMP} $*" >> "${logFile}"
  else
    TIMESTAMP="$(date '+%H:%M:%S')"
    echo "${TIMESTAMP} $*" >> "${logFile}"
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
