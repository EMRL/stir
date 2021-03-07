#!/usr/bin/env bash
#
# bugsnag.sh
#
###############################################################################
# Bugsnag integration
###############################################################################

# Initialize variables
var=(BUGSNAG_ORG)
init_loop

function test_bugsnag() { 
  if [[ -n "${BUGSNAG_AUTH}" ]]; then
    trace status "Testing Bugsnag... "
    # Test goes here
    BUGSNAG_ORG=$(${curl_cmd} --silent --get "https://api.bugsnag.com/user/organizations" --header "Authorization: token ${BUGSNAG_AUTH}" --header "X-Version: 2" | get_json_value id 1)
    if [[ -z "${BUGSNAG_ORG}" ]]; then
      trace notime "FAIL"
    else
      trace notime "OK (Org. #${BUGSNAG_ORG})"
    fi
  fi
}
