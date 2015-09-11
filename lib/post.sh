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
      trace "running email integration"
      echo $notes | mail -r $USER@$FROMDOMAIN -s "$(echo -e $SUBJECT "-" ${APP^^}"\nContent-Type: text/plain")" $POSTEMAIL
    else
      trace "Integration email address" $POSTEMAIL "does not look valid. Check your configuration."
    fi
  fi
}