#!/usr/bin/env bash
#
# lock.sh
#
###############################################################################
# Locks deployment process
###############################################################################

# Define lock file location
LOCK_FILE="/tmp/$APP.lock"

function lock() {
  if [[ -f "${LOCK_FILE}" ]]; then
    # Unlock?
    if [[ "${UNLOCK}" == "1" ]]; then
      rm "${LOCK_FILE}"
      notice "${WORK_PATH}/${APP} is now unlocked."
      quiet_exit
    else
      warning "${WORK_PATH}/${APP} is already being deployed in another instance."
      quiet_exit
    fi
  else
    trap 'rm -f "${LOCK_FILE}"' EXIT
    trace "Creating lockfile"
      touch "${LOCK_FILE}"
  fi
}
