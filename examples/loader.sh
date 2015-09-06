#!/bin/bash
#
# loader.sh
#
# A sub-wrapper for loading external functions.

# Creating this function first, so verbose output option is usable early
function trace () {
  if [[ $VERBOSE -eq 1 ]]; then
    echo -e "${tan}TRACE:${endColor} $@"
  fi
}

# Source everything in /lib
SOURCE="${BASH_SOURCE[0]}"
while [ -h "${SOURCE}" ]; do 
  DIR="$( cd -P "$( dirname "${SOURCE}" )" && pwd )"
  SOURCE="$(readlink "${SOURCE}")"
  [[ ${SOURCE} != /* ]] && SOURCE="${DIR}/${SOURCE}"
done
SOURCEPATH="$( cd -P "$( dirname "${SOURCE}" )" && pwd )"

if [ ! -d "${SOURCEPATH}" ]
then
  die "Failed to find library files expected in: ${SOURCEPATH}"
fi
for utility_file in "${SOURCEPATH}"/*.sh
do
  if [ -e "${utility_file}" ]; then
    # Don't source self
    if [[ "${utility_file}" == *"loader.sh"* ]]; then
      continue
    fi
    source "$utility_file"
  fi
done