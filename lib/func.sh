#!/bin/bash
#
# func.sh
#
# Handles various setup, logging, and option flags 

# Make sure this function is loaded up first

trace "Loading func.sh"

# Open a deployment session, ask for user confirmation before beginning
function go() {			
	cd $WORKPATH/$APP; \
	info "deploy" $VERSION
	printf "Current working path is %s\n" ${WORKPATH}/${APP}
	emptyLine

	if yesno --default yes "Continue? [Y/n] "; 
	then
		trace "Loading project."
	else
  		info "Exiting."
  		safeExit
	fi
}

# Progress spinner; we'll see if this works
function spinner() {
    local pid=$1
    local delay=0.25
    local spinstr='|/-\'
    tput civis;
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf "Working... %c  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b\b\b\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
    tput cnorm;
}

# Progress bar
function ProgressBar() {
    let _progress=(${1}*100/${2}*100)/100
    let _done=(${_progress}*4)/10
    let _left=40-$_done

    _fill=$(printf "%${_done}s")
    _empty=$(printf "%${_left}s")
	printf "\rProgress : [${_fill// /#}${_empty// /-}] ${_progress}%%"
}

function safeExit() {
    #mail -s "$SUBJECT: $APP" $TO < $logFile
    rm $logFile
    exit
}