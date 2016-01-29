#!/bin/bash
#
# activeCheck()
#
# Check for modified files. This will hopefully find files modified a user *other*
# than the user currently executing the deploy command. Still looking into the best way to do this.
trace "Loading activeCheck()"

function activeCheck() {
	trace "Sorry, nothing here."
# find . -mmin -10 -ls 
# 
}
