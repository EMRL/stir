#!/bin/bash
#
# minaDeploy()
#
# Handles deployment via mina
trace "Loading pkgDeploy()"   

function pkgDeploy() {
  emptyLine
  if  [ "$FORCE" = "1" ] || yesno --default yes "Deploy to live server? [Y/n] "; then
    # Add ssh keys and double check directoy
    ssh-add &>> $logFile
    cd $WORKPATH/$APP; \

    # deploy via deployment command specified in mina
    if [[ $VERBOSE -eq 1 ]]; then
      $DEPLOY | tee --append $trshFile               
    else
      $DEPLOY &>> $trshFile &
      spinner $!
    fi
    log "Deployment Summary"
    log "=================="
    git whatchanged -1 &>> $logFile &
  else
    safeExit
  fi   
}