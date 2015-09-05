#!/bin/bash
#
# npm()
#
# Checks if project uses node.js, and runs package manager if needed.
# Also checks for Grunt, for backward compatibility with CAA.
trace "Loading lock()"

# Define lock file location
LOCK_FILE=/tmp/$SITE.lock

function lock() {
	if [ -f "$LOCK_FILE" ]; then
		error $WORKPATH/$SITE "is already being deployed in another instance."
   		exit
	fi

	trap "rm -f $LOCK_FILE" EXIT
	trace "Creating lockfile"
	touch $LOCK_FILE
}