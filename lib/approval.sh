#!/usr/bin/env bash
#
# approval.sh
#
###############################################################################
# Handles deployment approval queue
############################################################################### 

# Initialize variables
var=(QUEUED)
init_loop

function queue() {
	info "Approval functionality is deprecated and has been removed."
	quietExit
}

function approve() {
	info "Approval functionality is deprecated and has been removed."
	quietExit
}

function deny() {
	info "Approval functionality is deprecated and has been removed."
	quietExit
}

# Check for approval queue
function queue_check() {
	if [[ -f "${WORKPATH}/${APP}/.queued" ]]; then
		info "Approval functionality is deprecated and has been removed."
	  quietExit
	fi
}
