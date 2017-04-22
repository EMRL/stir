#!/bin/bash
#
# approval.sh
#
# Handles deployment approval queue
trace "Loading approval functions"   

function queue() {
	# Make sure there's something to do
	gitStatus
	gitCommit
	(git status --porcelain | sed s/^...//) >> "${WORKPATH}/${APP}/.queued"
	info "Queuing proposed updates for approval"
	safeExit
	# slackPost
}

function approve() {
	info "Approving proposed updates"
	# Read proposed commit message from the first line of .queued
	notes="$(head -n 1 ${WORKPATH}/${APP}/.queued)"
	# Remove first line
	sed -i -e "1d" "${WORKPATH}/${APP}/.queued"
	# Loop through file, git add each file (line)
	while read QUEUED; do
	  git add "${QUEUED}"
	done < "${WORKPATH}/${APP}/.queued"
	git commit -m "${notes}" &>> "${logFile}"; errorChk
	trace "Commit message: ${notes}"
}

function deny() {
	info "Denying proposed updates"
}
