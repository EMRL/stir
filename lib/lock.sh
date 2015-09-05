#!/bin/bash
#
# npm()
#
# Checks if project uses node.js, and runs package manager if needed.
# Also checks for Grunt, for backward compatibility with CAA.
echo "DEBUG: Loading lock()"

LOCK_FILE=/tmp/$SITE.lock

function lock() {
	if [ -f "$LOCK_FILE" ]; then
		echo "FATAL: " $SITE " is already being deployed in another instance."
   		exit
	fi

trap "rm -f $LOCK_FILE" EXIT
echo "DEBUG: Creating lockfile" ; echo ""
touch $LOCK_FILE
}