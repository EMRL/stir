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
        ssh-add &>> $logFile
        cd $WORKPATH/$APP; \

		if [[ $VERBOSE -eq 1 ]]; then
			mina deploy | tee --append $logFile               
		else
		    mina deploy &>> $logFile &
        	spinner $!
       	fi
    else
        safeExit
    fi   
}