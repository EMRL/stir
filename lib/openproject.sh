#!/usr/bin/env bash
#
# openproject.sh
#
###############################################################################
# Handles integration with OpenProject
###############################################################################

# Initialize internal variables
var=(op_payload op_response op_http_code op_duration op_user)
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
# op_test()
#   Test OpenProject configuration and authentication
###############################################################################
function op_test() {

  notice "Checking OpenProject settings" 
  console_inline "Testing integration... "

  # Make sure required configuration exists
  if [[ -z "${OPENPROJECT_URL}" ]] || [[ -z "${OPENPROJECT_TOKEN}" ]]; then
    console "FAIL"

    [[ -z "${OPENPROJECT_URL}" ]] && \
      warning "OPENPROJECT_URL is not configured."

    [[ -z "${OPENPROJECT_TOKEN}" ]] && \
      warning "OPENPROJECT_TOKEN is not configured."

    return 1
  fi

  console "OK"

  # Build API URL
  clean_path "${OPENPROJECT_URL}/api/v3/users/me"

  # Test authentication
  op_response="$(
    "${curl_cmd}" \
      --silent \
      --show-error \
      --write-out $'\n%{http_code}' \
      --header "Authorization: Bearer ${OPENPROJECT_TOKEN}" \
      --header "Accept: application/hal+json" \
      "${cleaned_path}"
  )"

  # Separate response body and HTTP status
  op_http_code="${op_response##*$'\n'}"
  op_payload="${op_response%$'\n'*}"

  console_inline "Checking user... "
  
  if [[ "${op_http_code}" == "200" ]]; then
    op_user="$(get_json_value name 1 <<< "${op_payload}")"

    if [[ -n "${op_user}" ]]; then
      console "OK (${op_user})"
    else
      console "OK"
    fi
  else
    warning "FAIL (HTTP ${op_http_code})"
    return 1
  fi

  # Check configured work package
  console_inline "Checking work package... "

  if [[ -z "${OPENPROJECT_WORK_PACKAGE}" ]]; then
    warning "FAIL: OPENPROJECT_WORK_PACKAGE is not configured."
    return 1
  fi

  clean_path "${OPENPROJECT_URL}/api/v3/work_packages/${OPENPROJECT_WORK_PACKAGE}"

  op_response="$(
    "${curl_cmd}" \
      --silent \
      --show-error \
      --write-out $'\n%{http_code}' \
      --header "Authorization: Bearer ${OPENPROJECT_TOKEN}" \
      --header "Accept: application/hal+json" \
      "${cleaned_path}"
  )"

  op_http_code="${op_response##*$'\n'}"
  op_payload="${op_response%$'\n'*}"

  if [[ "${op_http_code}" == "200" ]]; then
    op_subject="$(get_json_value subject 1 <<< "${op_payload}")"
    console "OK (#${OPENPROJECT_WORK_PACKAGE}: ${op_subject})"
  else
    warning "FAIL (HTTP ${op_http_code})"
    return 1
  fi

  # Check configured time
  console_inline "Checking time value... "

  if [[ -n "${OPENPROJECT_ADD_TIME}" ]]; then
    console "OK (${OPENPROJECT_ADD_TIME})"
  else
    warning "FAIL: OPENPROJECT_ADD_TIME is not configured."
    return 1
  fi
}
