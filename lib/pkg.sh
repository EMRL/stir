#!/bin/bash
#
# pkgDeploy()
#
# Handles deployment via mina
trace "Loading pkgDeploy()"   

function pkgDeploy() {
  emptyLine
  if  [ "$FORCE" = "1" ] || yesno --default yes "Deploy to live server? [Y/n] "; then
    # Add ssh keys and double check directoy
    cd $WORKPATH/$APP; \
    ssh-add &>> $logFile; sleep 2

    # Deploy via deployment command specified in mina
    if [[ $VERBOSE -eq 1 ]]; then
      $DEPLOY | tee --append $logFile
      # git show --stat &>> $logFile 
      postDeploy
      info "Deployment Success."
    else
      $DEPLOY &>> $logFile &
      spinner $!
      # git show --stat &>> $logFile
      postDeploy
      info "Deployment Success.";
    fi

  else
    # Run whatever integrations might be setup
    safeExit
  fi   
}