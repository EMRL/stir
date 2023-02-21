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
var=(MAUTIC_URL MAUTIC_AUTH MAUTIC_LEGACY_VERSION working_subject \
  working_sentCount working_readCount working_readCount working_readRate \
  working_publishUp working_isPublished current_mtc_value mtc_valid mtc_id_1 \
  mtc_isPublished_1 mtc_subject_1 mtc_publishUp_1 mtc_sentCount_1 \
  mtc_readCount_1 mtc_readRate_1 mtc_id_2 mtc_isPublished_2 mtc_subject_2 \
  mtc_publishUp_2 mtc_sentCount_2 mtc_readCount_2 mtc_readRate_2 mtc_id_3 \
  mtc_isPublished_3 mtc_subject_3 mtc_publishUp_3 mtc_sentCount_3 \
  mtc_readCount_3 mtc_readRate_3)
init_loop

function mtc_data_loop() {
  mtc_var=(isPublished subject publishUp sentCount readCount emailType)  

  # Get payload
  clean_path "${MAUTIC_URL}/api/emails?limit=7&orderBy=id&orderByDir=desc"
  # trace "${curl_cmd} --silent --get \"${cleaned_path}\" --header \"Authorization: Basic ${MAUTIC_AUTH}\""
  mtc_payload="$(${curl_cmd} --silent --get "${cleaned_path}" --header "Authorization: Basic ${MAUTIC_AUTH}")"; error_check

  if [[ -n "${mtc_payload}" ]]; then
    mtc_valid="1"
  fi

  # Start the loop
  for i in {1..3} ; do
    for j in "${mtc_var[@]}" ; do
      current_mtc_value="$(echo ${mtc_payload} | get_json_value ${j} ${i})"; dot     
      # Old versions of Mautic prefix their variables with a space
      # so here's the fix (well really it's a break)
      if [[ "${MAUTIC_LEGACY_VERSION}" == "TRUE" ]]; then
        current_mtc_value="${current_mtc_value:1}"
      fi
      if [[ -z "${current_mtc_value}" ]]; then
        return
      else
        if [[ "${j}" == "subject" ]]; then
          current_mtc_value=$(echo ${current_mtc_value} | sed 's/[^a-zA-Z0-9 ]//g')
        fi
        if [[ "${j}" == "publishUp" ]]; then
          current_mtc_value="${current_mtc_value::-3}"
          clean_date "${current_mtc_value}"
          current_mtc_value="${cleaned_date}"
        fi
        eval "mtc_${j}_${i}=\"${current_mtc_value}\"" 
      fi 
    done 
    mtc_read_rate
  done
}

function mtc_read_rate() {
  # Calculate read rate in percent
  working_sentCount="mtc_sentCount_${i}"
  working_readCount="mtc_readCount_${i}"
  if [[ "${!working_readCount}" == "0" ]]; then
    working_readRate="0"
  else
    working_readRate="$(awk "BEGIN { pc=100*${!working_readCount:-}/ \
      ${!working_sentCount:-}; i=int(pc); print (pc-i<0.5)?i:i+1 }")"
  fi
  eval "mtc_readRate_${i}=\"${working_readRate}\""
}

function mtc_test() {
  mtc_data_loop
  # Output test values to console
  for i in {1..3} ; do
    empty_line
    working_isPublished="mtc_isPublished_${i}"
    working_subject="mtc_subject_${i}"
    working_publishUp="mtc_publishUp_${i}"
    console "Subject: ${!working_subject}"
     if [[ "${!working_isPublished}" == "true" ]]; then
      mtc_read_rate
      working_readRate="mtc_readRate_${i}"
      console "Published: ${!working_publishUp}"
      if [[ "${!working_sentCount}" == "0" ]]; then
        console "Sent: Pending"
      else
        console "Sent: ${!working_sentCount}"
        console "Read: ${!working_readCount} (${!working_readRate}%)"
      fi
    else
      console "Published: ${!working_isPublished}"
    fi
  done
}
