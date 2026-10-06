#!/usr/bin/env bash
#
# openproject.sh
#
###############################################################################
# Handles integration with OpenProject
###############################################################################

# Initialize internal variables
var=(op_payload op_response op_http_code op_duration)
init_loop

###############################################################################
# op_addtime()
#   Logs time to the assigned OpenProject work package
###############################################################################      
function op_addtime() {
  trace "Adding ${OPENPROJECT_ADD_TIME} to work \
    package #${OPENPROJECT_WORK_PACKAGE}"
}

###############################################################################
# op_addtime()
#   Test OpenProject configuration
###############################################################################      
function op_test() {
  trace "OpenProject connection: "
  if [[ -n "${OPENPROJECT_URL}" ]]; then
    trace status "OK"
    # Test goes here
  else
    trace notime status "FAIL"
  fi
}
