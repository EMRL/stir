#!/usr/bin/env bash
#
# bulk.stir.sh
#
###############################################################################
# A small script to bulk stir all the projects in a directory
###############################################################################

# Declare the root path of all your projects that you want to stir in bulk
if [[ -f "/etc/stir/global.conf" ]]; then 
    source "/etc/stir/global.conf"
fi

if [[ -z "${WORK_PATH}" ]]; then
    echo "bulk.stir requires WORK_PATH to be defined; please install and configure stir globally."
    exit 1
fi

function error_check() {
    EXITCODE=$?;
    if [[ "${EXITCODE}" -ne "0" ]]; then
        exit 1
    fi
}

# Create array from directory names
IFS=$'\n' read -r -d '' -a var < <(find "${WORK_PATH}" -maxdepth 1 -mindepth 1 -type d -printf '%P\n')

# Loop through
for i in "${var[@]}" ; do
    stir $1 "${i}"; error_check
done
