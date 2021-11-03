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
var=(MAUTIC_URL MAUTIC_AUTH working_subject working_sentCount \
  working_readCount working_readRate mtc_payload mtc_subject \
  mtc_sentCount mtc_readCount mtc_emailType mtc_readRate \
  current_mtc_value)
init_loop

function mtc_data_loop() {
  mtc_var=(subject sentCount readCount emailType)  

  # Get payload
  mtc_payload="$(${curl_cmd} --silent --get "${MAUTIC_URL}api/emails?limit=3&orderBy=id&orderByDir=desc" --header "Authorization: Basic ${MAUTIC_AUTH}")"; error_check

  # Start the loop
  # This is gonna be clunky until we have a loops within loops. We're after the
  # most recent 3 email stats and Mautic not making it simple
  for i in {1..3} ; do
    for j in "${mtc_var[@]}" ; do
      # declare mtc_${j}_${i}="$(echo ${mtc_payload} | get_json_value ${j} ${i})"
      current_mtc_value="$(echo ${mtc_payload} | get_json_value ${j} ${i})"
      if [[ -z "${current_mtc_value}" ]]; then
        return
      else
        eval "mtc_${j}_${i}=\"${current_mtc_value}\""
      fi
    done
    # Calulate percentage read rates
    # working_readCount="mtc_readCount_${i}"
    # working_sentCount="mtc_sentCount_${i}"
    # mtc_readRate_${i}="$(awk "BEGIN { pc=100*${working_readCount}/${working_sentCount}; i=int(pc); print (pc-i<0.5)?i:i+1 }")"
    # mtc_readRate_${i}="$(get_percent ${working_sentCount}} ${working_readCount})"
  done
}

function mtc_test() { 
  mtc_data_loop
  # Output test values to console
  for i in {1..3} ; do
    empty_line
    working_subject="mtc_subject_$i"
    working_sentCount="mtc_sentCount_${i}"
    working_readCount="mtc_readCount_${i}"
    working_readRate="mtc_readRate_${i}"
    console "Subject:${!working_subject}"
    console "Sent:${!working_sentCount}"
    console "Read:${!working_readCount} (${mtc_readRate}%)"
  done

}

function mtc_obsolete() {
  # Output test values to console
  for i in {1..3} ; do
    working_subject="mtc_subject_$i"
    working_sentCount="mtc_sentCount_${i}"
    working_readCount="mtc_readCount_${i}"
    working_readRate="mtc_readRate_${i}"
    console "Subject:${!working_subject}"
    console "Sent:${working_sentCount}"
    console "Read:${working_readCount} (${mtc_readRate}%)"
  done
}

function mtc_test_dev() { 
  if [[ -n "${MAUTIC_AUTH}" ]]; then
    trace status "Testing Mautic integration... "
    # We test by getting the most recent emails stats
    mtc_payload="$(${curl_cmd} --silent --get "${MAUTIC_URL}api/emails?limit=1&orderBy=id&orderByDir=desc" --header "Authorization: Basic ${MAUTIC_AUTH}")"; error_check
    
    mtc_subject="$(echo ${mtc_payload} | get_json_value subject 1)"
    mtc_sent="$(echo ${mtc_payload} | get_json_value sentCount 1)"
    mtc_read="$(echo ${mtc_payload} | get_json_value readCount 1)"
    mtc_type="$(echo ${mtc_payload} | get_json_value emailType 1)"
    mtc_readrate="$(awk "BEGIN { pc=100*${mtc_read}/${mtc_sent}; i=int(pc); print (pc-i<0.5)?i:i+1 }")"
    mtc_readrate="$(get_percent ${mtc_sent} ${mtc_read})"    
  fi
  
  if [[ -z "${mautic_payload}" ]]; then
    trace notime "FAIL"
  else
    trace notime "OK"
    trace "Most recent email:${mtc_subject}"
    trace "Sent:${mtc_sent}"
    trace "Read:${mtc_read} (${mtc_readrate}%)"
    trace "Type:${mtc_type}"
  fi
}
