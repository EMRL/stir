#!/usr/bin/env bash
#
# server-check.sh
#
###############################################################################
# Check to see if production environment is online and running web server
###############################################################################

function check_server() {
  if [[ "${CHECK_SERVER}" == "TRUE" ]]; then
    notice "Checking servers..."
    # Set SERVERFAIL to 0
    SERVERFAIL="0"
    if [[ -z "${REPO}" ]]; then
      trace "No repo name set, skipping check"
    else
      # For now, we'll use 200, 301, or 401 to indicate all is working well cause 
      # Bitbucket is being a noob; I'll make this better later
      REPOURL="${REPO_HOST}/${REPO}/"
      if "${curl_cmd}" -sL --head "${REPO_HOST}" | grep -E "200|301|401" > /dev/null; then
        console " $REPO_HOST/$REPO/ ${tan}OK${endColor}";
      else
        console " $REPO_HOST/$REPO/ ${red}FAIL${endColor}"
        trace " $REPO_HOST/$REPO/ FAIL"; SERVERFAIL="1"
      fi
    fi

    if [[ -z "${DEV_URL}" ]]; then
      trace "No staging URL set, skipping check"
    else
      # Should return "200 OK" if all is working well
      if "${curl_cmd}" -sL --head "${DEV_URL}" | grep -a "200 OK" > /dev/null; then
        console " ${DEV_URL} (staging) ${tan}OK${endColor}";
      else
        console " ${DEV_URL} (staging) ${red}FAIL${endColor}"
        trace " ${DEV_URL} (staging) FAIL"; SERVERFAIL="1"
      fi
    fi

    if [[ -z "${PROD_URL}" ]]; then
      trace "No production URL set, skipping check"
    else
      # Should return "200 OK" if all is working well
      if "${curl_cmd}" -sL --head "${PROD_URL}" | grep -a "200 " > /dev/null; then
        console " ${PROD_URL} (production) ${tan}OK${endColor}"
      else
        console " ${PROD_URL} (production) ${red}FAIL${endColor}"
        trace " ${PROD_URL} (production) FAIL"; SERVERFAIL="1"
      fi
    fi

    # Did anything fail?
    if [ "${SERVERFAIL}" == "1" ]; then
      console; error "Fix server issues before continuing.";
    else
      trace "Servers return OK"
    fi
  fi
}
