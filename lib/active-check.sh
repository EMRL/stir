#!/bin/bash
#
# activeCheck()
#
# Check for modified files. This will hopefully find files modified a user *other*
# than the user currently executing the deploy command. Still looking into the best way to do this.
trace "Loading active_check()"

function activeCheck() {
	trace "Checking for active files"
	active_files=(find $WORKPATH/$APP -mmin -10 -ls)
	if [ ! -z "$active_files" ]; then
		error "Code base has changed within the last 10 minutes. Halting deployment."
	fi
}
