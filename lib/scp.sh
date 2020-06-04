#!/usr/bin/env bash
#
# scp.sh
#
###############################################################################
# Extremely simple deployment via scp
###############################################################################

# Initialize variables
var=(STAGING_DEPLOY_PATH PRODUCTION_DEPLOY_HOST PRODUCTION_DEPLOY_PATH \
  SCP_DEPLOY_USER SCP_DEPLOY_PASS)
init_loop

function deploy_scp() {
  # This is ghetto
  if [[ -n "${PRODUCTION_DEPLOY_PATH}" ]]; then
    # if SCPPORT is empty, set it to 22
    if [[ -z "${SCP_DEPLOY_PORT}" ]]; then
      SCP_DEPLOY_PORT="22"
    fi

    # TODO: Modernize this for compatability with multple non-master branches
    # Checkout production branch
    if [[ -n "${PRODUCTION}" ]]; then
      # Remove this requirement at some point
      MERGE="1"
      checkout "${PRODUCTION}"
    else
      error "Production branch must be defined"
      return
    fi

    # TODO: Add proper checks/fallbacks here
    TMP=$(<$SCP_DEPLOY_PASS)
    SCP_DEPLOY_PASS="${TMP}"
    sshpass -p "${SCP_DEPLOY_PASS}" scp -o StrictHostKeyChecking=no -P "${SCP_DEPLOY_PORT}" -r -v "${WORKPATH}/${APP}/${STAGING_DEPLOY_PATH}"/* "${SCP_DEPLOY_USER}@${PRODUCTION_DEPLOY_HOST}:${PRODUCTION_DEPLOY_PATH}/"  &>> "${logFile}"; error_check;

    # Checkout master and move on
    checkout "${MASTER}"

  else
    echo "ERROR: Can not find production server path"; return
  fi 
}
