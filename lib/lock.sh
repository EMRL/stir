#!/bin/bash
#
# lock()
#
# Process locking
trace "Locking process"

# Define lock file location
LOCK_FILE=/tmp/$APP.lock

function lock() {
  trace "Creating lockfile"

  if [ -f "$LOCK_FILE" ]; then
    warning "${WORKPATH}/${APP} is already being deployed in another instance."
    exit
  fi

  trap 'rm -f "${LOCK_FILE}"' EXIT
  touch "${LOCK_FILE}"
}
