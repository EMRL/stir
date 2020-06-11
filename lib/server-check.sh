#!/usr/bin/env bash
#
# server-check.sh
#
###############################################################################
# Check to see if production environment is online and running web server
###############################################################################

function server_check() {
  if [[ "${SERVERCHECK}" == "TRUE" ]]; then
    notice "Checking servers..."
    # Set SERVERFAIL to 0
    SERVERFAIL="0"
    if [[ -z "${REPO}" ]]; then
      trace "No repo name set, skipping check"
    else
      # For now, we'll use 200, 301, or 401 to indicate all is working well cause 
      # Bitbucket is being a noob; I'll make this better later
      REPOURL="${REPOHOST}/${REPO}/"
      if "${curl_cmd}" -sL --head "${REPOHOST}" | grep -E "200|301|401" > /dev/null; then
        console " $REPOHOST/$REPO/ ${tan}OK${endColor}";
      else
        console " $REPOHOST/$REPO/ ${red}FAIL${endColor}"
        trace " $REPOHOST/$REPO/ FAIL"; SERVERFAIL="1"
      fi
    fi

    if [[ -z "${DEVURL}" ]]; then
      trace "No staging URL set, skipping check"
    else
      # Should return "200 OK" if all is working well
      if "${curl_cmd}" -sL --head "${DEVURL}" | grep -a "200 OK" > /dev/null; then
        console " ${DEVURL} (staging) ${tan}OK${endColor}";
      else
        console " ${DEVURL} (staging) ${red}FAIL${endColor}"
        trace " ${DEVURL} (staging) FAIL"; SERVERFAIL="1"
      fi
    fi

    if [[ -z "${PRODURL}" ]]; then
      trace "No production URL set, skipping check"
    else
      # Should return "200 OK" if all is working well
      if "${curl_cmd}" -sL --head "${PRODURL}" | grep -a "200 " > /dev/null; then
        console " ${PRODURL} (production) ${tan}OK${endColor}"
      else
        console " ${PRODURL} (production) ${red}FAIL${endColor}"
        trace " ${PRODURL} (production) FAIL"; SERVERFAIL="1"
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
