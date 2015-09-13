#!/bin/bash
#
# postCommit()
#
# Handles integration with other services
trace "Loading postCommit()"

# Compile commit message with other stuff for integration
function buildLog() {
	# OK let's grab the short version of the commit hash
	COMMITHASH="$(git rev-parse --short HEAD)"; COMMITURL="https://bitbucket.org/emrl/"$REPO"/commits/"$COMMITHASH
	TASKLOG="$notes"$'\n'"<a href=\"$COMMITURL\">Commit $COMMITHASH"
	trace "Posting '"$TASKLOG"'"
	echo $TASKLOG | mail -r $USER@$FROMDOMAIN -s "$(echo -e $SUBJECT "-" ${APP^^}"\nContent-Type: text/plain")" $POSTEMAIL
	# echo $COMMITHASH - $notes > $postFile; echo $COMMITURL >> $postFile
	# cat $TASKLOG | mail -r $USER@$FROMDOMAIN -s "$(echo -e $SUBJECT "-" ${APP^^}"\nContent-Type: text/plain")" $POSTEMAIL
}

# Post via email
function postCommit() {
	# Check to see if there's an email integration setup
	if [[ -z "$POSTEMAIL" ]]; then
		trace "No email integration setup"
	else
	# Is it a valid email address? Ghetto check but better than nothing
	if [[ "$POSTEMAIL" == ?*@?*.?* ]]; then
		trace "Running email integration"
		buildLog
	else
		trace "Integration email address" $POSTEMAIL "does not look valid. Check your configuration."
	fi
  fi
}