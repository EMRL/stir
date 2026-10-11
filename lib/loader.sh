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
trace() {
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

# Find the /lib directory
SOURCE="${BASH_SOURCE[0]}"

while [[ -h "${SOURCE}" ]]; do
  DIR="$(cd -P "$(dirname "${SOURCE}")" && pwd)"
  SOURCE="$(readlink "${SOURCE}")"
  [[ "${SOURCE}" != /* ]] && SOURCE="${DIR}/${SOURCE}"
done

SOURCE_PATH="$(cd -P "$(dirname "${SOURCE}")" && pwd)"

if [[ ! -d "${SOURCE_PATH}" ]]; then
  echo "Failed to find library files expected in: ${SOURCE_PATH}"
  exit 1
fi

# Source everything in /lib recursively
while IFS= read -r -d '' library; do
  # Don't source yourself, silly script
  if [[ "${library}" == "${SOURCE_PATH}/loader.sh" ]]; then
    continue
  fi

  # shellcheck disable=SC1090
  source "${library}"
done < <(
  find "${SOURCE_PATH}" -type f -name '*.sh' -print0 |
    sort -z
)
