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
	quiet_exit
}

function approve() {
	info "Approval functionality is deprecated and has been removed."
	quiet_exit
}

function deny() {
	info "Approval functionality is deprecated and has been removed."
	quiet_exit
}

# Check for approval queue
function queue_check() {
	if [[ -f "${WORK_PATH}/${APP}/.queued" ]]; then
		info "Approval functionality is deprecated and has been removed."
	  quiet_exit
	fi
}
