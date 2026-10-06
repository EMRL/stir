#!/usr/bin/env bash
#
# openproject.sh
#
###############################################################################
# Handles integration with OpenProject
###############################################################################

# Initialize internal variables
var=(op_payload op_response op_http_code op_duration op_user op_subject \
  op_comment)
init_loop

###############################################################################
# op_addtime()
#   Logs time to the assigned OpenProject work package and adds the commit
#   message to the work package activity feed
###############################################################################
function op_addtime() {

  # Make sure required configuration exists
  if [[ -z "${OPENPROJECT_URL}" ]] || \
     [[ -z "${OPENPROJECT_TOKEN}" ]] || \
     [[ -z "${OPENPROJECT_WORK_PACKAGE}" ]] || \
     [[ -z "${OPENPROJECT_ADD_TIME}" ]] || \
     [[ -z "${OPENPROJECT_ACTIVITY}" ]]; then
    warning "OpenProject time logging is not configured correctly."
    return 1
  fi

  # Convert configured time to ISO 8601
  if [[ "${OPENPROJECT_ADD_TIME}" =~ ^([0-9]+)m$ ]]; then
    op_duration="PT${BASH_REMATCH[1]}M"
  elif [[ "${OPENPROJECT_ADD_TIME}" =~ ^([0-9]+)h$ ]]; then
    op_duration="PT${BASH_REMATCH[1]}H"
  elif [[ "${OPENPROJECT_ADD_TIME}" =~ ^([0-9]+)h([0-9]+)m$ ]]; then
    op_duration="PT${BASH_REMATCH[1]}H${BASH_REMATCH[2]}M"
  else
    warning "Invalid OPENPROJECT_ADD_TIME value: ${OPENPROJECT_ADD_TIME}"
    return 1
  fi

  # Use the commit message as the time entry/activity comment
  op_comment="${notes:-Automated maintenance via Stir}"

  # Escape characters that would break JSON
  op_comment="${op_comment//\\/\\\\}"
  op_comment="${op_comment//\"/\\\"}"
  op_comment="${op_comment//$'\n'/\\n}"
  op_comment="${op_comment//$'\r'/}"

  # Build API URL
  clean_path "${OPENPROJECT_URL}/api/v3/time_entries"

  # Build time entry payload
  op_payload="{
    \"spentOn\": \"$(date +%Y-%m-%d)\",
    \"hours\": \"${op_duration}\",
    \"comment\": {
      \"format\": \"plain\",
      \"raw\": \"${op_comment}\"
    },
    \"_links\": {
      \"entity\": {
        \"href\": \"/api/v3/work_packages/${OPENPROJECT_WORK_PACKAGE}\"
      },
      \"activity\": {
        \"href\": \"/api/v3/time_entries/activities/${OPENPROJECT_ACTIVITY}\"
      }
    }
  }"

  # Log time
  op_response="$(
    "${curl_cmd}" \
      --silent \
      --show-error \
      --request POST \
      --write-out $'\n%{http_code}' \
      --header "Authorization: Bearer ${OPENPROJECT_TOKEN}" \
      --header "Content-Type: application/json" \
      --header "Accept: application/hal+json" \
      --data "${op_payload}" \
      "${cleaned_path}"
  )"

  # Separate response body and HTTP status
  op_http_code="${op_response##*$'\n'}"
  op_response="${op_response%$'\n'*}"

  if [[ "${op_http_code}" != "201" ]]; then
    warning "Unable to log OpenProject time (HTTP ${op_http_code})."
    log "${op_response}"
    return 1
  fi

  # Add commit message to work package activity feed
  clean_path \
    "${OPENPROJECT_URL}/api/v3/work_packages/${OPENPROJECT_WORK_PACKAGE}/activities?notify=false"

  op_payload="{
    \"comment\": {
      \"raw\": \"${op_comment}\"
    }
  }"

  op_response="$(
    "${curl_cmd}" \
      --silent \
      --show-error \
      --request POST \
      --write-out $'\n%{http_code}' \
      --header "Authorization: Bearer ${OPENPROJECT_TOKEN}" \
      --header "Content-Type: application/json" \
      --header "Accept: application/hal+json" \
      --data "${op_payload}" \
      "${cleaned_path}"
  )"

  # Separate response body and HTTP status
  op_http_code="${op_response##*$'\n'}"
  op_response="${op_response%$'\n'*}"

  if [[ "${op_http_code}" == "201" ]]; then
    info "Logged ${OPENPROJECT_ADD_TIME} to OpenProject work package #${OPENPROJECT_WORK_PACKAGE}."
  else
    warning "Time logged, but unable to add OpenProject activity comment (HTTP ${op_http_code})."
    log "${op_response}"
  fi
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

  # Check configured activity
  console_inline "Checking activity... "

  if [[ -n "${OPENPROJECT_ACTIVITY}" ]]; then
    console "OK (#${OPENPROJECT_ACTIVITY})"
  else
    warning "FAIL: OPENPROJECT_ACTIVITY is not configured."
    return 1
  fi
}
