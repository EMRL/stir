#!/bin/bash
#
# loader.sh
#
# A sub-wrapper for loading external functions.

# Save current contents of the terminal
tput smcup; clear

# Creating this function first, so verbose output option is usable early
function trace () {
	if [[ $VERBOSE -eq 1 ]]; then
		echo -e "${tan}TRACE:${endColor} $@"
		echo "TRACE: $@" >> $logFile
	else
		echo "TRACE: $@" >> $logFile
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
		echo "Failed to find library files expected in: ${SOURCEPATH}";
		exit 1
	fi
	for LIBRARIES in "${SOURCEPATH}"/*.sh
	do
	if [ -e "${LIBRARIES}" ]; then
		# Don't source yourself, silly script
		if [[ "${LIBRARIES}" == *"loader.sh"* ]]; then
			continue
		fi
		source "$LIBRARIES"
	fi
done