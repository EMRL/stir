#!/bin/bash
#
# postCommit()
#
# Handles integration with other services
trace "Loading postCommit()"

# Compile commit message with other stuff for integration
function buildLog() {
	trace "Posting '"$TASKLOG"'"
	# OK let's grab the short version of the commit hash
	COMMITHASH="$(git rev-parse --short HEAD)"; COMMITURL=$BITBUCKET"/"$REPO"/commits/"$COMMITHASH
	# Alright let's try to get a short URL
	id="7c005cbb4e"
	#output=`awk -F# '{gsub(/ /,"");print ($1) }' < /root/output`
	echo "Commit" $COMMITHASH":" $notes > $postFile
	# lynx -dump "http://emrl.co/yourls-api.php?signature=$id&action=shorturl&format=simply&url=$COMMITURL" > $urlFile
	# awk '{print $1}' $urlFile > $trshFile && mv $trshFile $urlFile;
	# echo $urlFile >> $postFile
	echo $COMMITURL >> $postFile
	(cat $postFile) | mail -r $USER@$FROMDOMAIN -s "$(echo -e $SUBJECT "-" ${APP^^}"\nContent-Type: text/plain")" $POSTEMAIL
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