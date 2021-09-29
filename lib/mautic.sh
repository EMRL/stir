#!/usr/bin/env bash
#
# bugsnag.sh
#
###############################################################################
# Mautic integration
###############################################################################

# Note: We're using basic authentication. Run this command in the shell to
# generate your token
# echo -n "user:pass" | base64 

# Initialize variables
var=(MAUTIC_URL MAUTIC_AUTH mtc_subject mtic_sent mtc_read mtc_readrate)
init_loop

function test_mautic() { 
  if [[ -n "${MAUTIC_AUTH}" ]]; then
    trace status "Testing Mautic integration... "
    # We test by getting the most recent emails stats
    mautic_payload="$(${curl_cmd} --silent --get "https://engage.abatinsacramento.com/api/emails?limit=1&orderBy=id&orderByDir=desc" --header "Authorization: Basic ${MAUTIC_AUTH}")"; error_check
    
    mtc_subject="$(echo ${mautic_payload} | get_json_value subject 1)"
    mtc_sent="$(echo ${mautic_payload} | get_json_value sentCount 1)"
    mtc_read="$(echo ${mautic_payload} | get_json_value readCount 1)"
    #mtc_readrate="$(awk "BEGIN { pc=100*${mtc_read}/${mtc_sent}; i=int(pc); print (pc-i<0.5)?i:i+1 }")"
    mtc_readrate="$(get_percent ${mtc_sent} ${mtc_read})"    
  fi
#    if [[ -z "${BUGSNAG_ORG}" ]]; then
#      trace notime "FAIL"
#    else
      trace notime "OK"
      trace "Most recent email:${mtc_subject}"
      trace "Sent:${mtc_sent}"
      trace "Read:${mtc_read} (${mtc_readrate}%)"
#    fi
#  fi
}
