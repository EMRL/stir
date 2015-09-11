#!/bin/bash
#
# postCommit()
#
# Handles integration with other services
trace "Loading postCommit()"

# Post commit message via email
function postCommit() {
  # Check to see if there's an email integration setup
  if [[ -z "$POSTEMAIL" ]]; then
    trace "No email integration setup"
  else
    # Is it a valid email address? Ghetto check but better than nothing
    if [[ "$POSTEMAIL" == ?*@?*.?* ]]; then
      trace "Running email integration"
      # OK let's grab the short version of the commit hash
      COMMITHASH="$(git rev-parse --short HEAD)"; COMMITURL="https://bitbucket.org/emrl/"$APP"/commits/"$COMMITHASH
      TASKLOG="$notes"$'\n'"$COMMITURL"
      trace "Posting '"$TASKLOG"'"
      echo $TASKLOG | mail -r $USER@$FROMDOMAIN -s "$(echo -e $SUBJECT "-" ${APP^^}"\nContent-Type: text/plain")" $POSTEMAIL
    else
      trace "Integration email address" $POSTEMAIL "does not look valid. Check your configuration."
    fi
  fi
}