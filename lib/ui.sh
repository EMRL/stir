#!/bin/bash
#
# ui.sh
#
# Handles interface components
trace "Loading ui.sh"

# Progress spinner; we'll see if this works
function spinner() {
	local pid=$1
	local delay=0.15
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

# Set up the progress bar function
function progressBar() {
	let _progress=(${1}*100/${2}*100)/100
	let _done=(${_progress}*4)/10
	let _left=40-$_done
	_fill=$(printf "%${_done}s")
	_empty=$(printf "%${_left}s")
	printf "\rProgress : [${_fill// /#}${_empty// /-}] ${_progress}%%"
}

# Display progress bar
function showProgress() {
		_start=1
		_end=100
		for number in $(seq ${_start} ${_end})
		do
		progressBar ${number} ${_end}
		done;
		emptyLine
}