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
      info "Deployment Success."             
    else
      $DEPLOY &>> $trshFile &
      spinner $!
      info "Deployment Success."
    fi
  else
    safeExit
  fi   
}