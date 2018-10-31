#!/usr/bin/env bash
#
# prepare.sh
#
###############################################################################
# Runs user-defined prepare command
###############################################################################

function prepare() {
  trace "This is an empty function"
  if [[ "${PREPARE_ONLY}" == "1" ]]; then
    quickExit
  fi
}
