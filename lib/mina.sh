#!/bin/bash
#
# minaDeploy()
#
# Handles deployment via mina
trace "Loading minaDeploy()"   

function minaDeploy() {
    emptyLine
    if yesno --default yes "Deploy to live server? [Y/n] "; then
        emptyLine
        ssh-add > $logFile
        cd $WORKPATH/$APP; \
        mina deploy
    else
        safeExit
    fi   
}