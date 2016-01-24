#!/bin/bash
#
# post-integration.sh
#
# Handles integration with other services
trace "Loading post-integration.sh"

# Compile commit message with other stuff for integration
function buildLog() {
	trace "Posting" $TASKLOG
	# OK let's grab the short version of the commit hash
	COMMITHASH="$(git rev-parse --short HEAD)"; COMMITURL=$REPOHOST"/"$REPO"/commits/"$COMMITHASH
	# Alright let's try to get a short URL
	id="7c005cbb4e"
	#output=`awk -F# '{gsub(/ /,"");print ($1) }' < /root/output`
	echo "<strong>Commit" $COMMITHASH"</strong>:" $notes > $postFile

	# Make a short URL, not implemented
	# lynx -dump "http://emrl.co/yourls-api.php?signature=$id&action=shorturl&format=simply&url=$COMMITURL" > $urlFile
	# awk '{print $1}' $urlFile > $trshFile && mv $trshFile $urlFile;
	# echo $urlFile >> $postFile
}

function mailPost {
	echo $COMMITURL >> $postFile
	(cat $postFile) | mail -r $USER@$FROMDOMAIN -s "$(echo -e $SUBJECT "-" ${APP^^}"\nContent-Type: text/plain")" $POSTEMAIL	
}
# Post via email
function postCommit() {
	# Check for a Wordpress core update, update production database if needed
	if [ "$UPDCORE" = "1" ]; then
		info "Upgrading production database..."; lynx -dump $PRODURL/system/wp-admin/upgrade.php > $trshFile
	fi
	# just for yuks, display git stats for this user (user can override this if it annoys them)
	gitStats
	# Is Slack integration configured?
	if [ "${POSTTOSLACK}" == "TRUE" ]; then
		trace "Slack integration seems to be configured. Posting to" $SLACKURL
		buildLog; slackPost > /dev/null 2>&1
	fi
	# Check to see if there's an email integration setup
	if [[ -z "$POSTEMAIL" ]]; then
		trace "No email integration setup"
	else
	# Is it a valid email address? Ghetto check but better than nothing
	if [[ "$POSTEMAIL" == ?*@?*.?* ]]; then
		trace "Running email integration"
		buildLog; mailPost
	else
		trace "Integration email address" $POSTEMAIL "does not look valid. Check your configuration."
	fi
  fi
}
