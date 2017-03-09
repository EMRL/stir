#!/bin/bash
#
# approval.sh
#
# Handles deployment approval queue
trace "Loading approval functions"   

function queue() {
	# Make sure there's something to do
	gitStatus
	info "Queuing proposed updates for approval"
	slackPost
}

function approve() {
	info "Approving proposed updates"
}

function deny() {
	info "Denying proposed updates"
}