#!/usr/bin/env bash
#
# config-check.sh
#
###############################################################################
# Check to see if configuration files need to be updated, and update if so
###############################################################################

# Initialize variables
read -r update_global update_user update_project env_settings project_config \
  sed_hack short_version global_project_version local_version \
  tmp_workpath <<< ""
echo "${update_global} ${update_user} ${update_project} ${project_config} 
  ${sed_hack} ${short_version} ${global_project_version} 
  ${local_version} ${tmp_workpath}" > /dev/null

function env_check() {
  # Only check when someone is at the console
  if [[ "${FORCE}" != "1" ]]; then
    # Save the workpath to reload after this process; this is to allow a 
    # deployment using to --current switch to continue properly after a global
    # configuration file update
    tmp_workpath="${WORKPATH}"

    # Trim alpha/beta part of version number   
    local_version="${VERSION//-*}"
    
    # Compare version numbers
    local_version="${GLOBAL_VERSION}"; source "${deployPath}"/deploy-example.conf
    [[ "${GLOBAL_VERSION}" != "${local_version}" ]] && update_global="1";
    
    local_version="${USER_VERSION}"; source "${deployPath}"/.deployrc
    [[ "${USER_VERSION}" != "${local_version}" ]] && update_user="1";
    
    local_version="${PROJECT_VERSION}"; source "${deployPath}"/deploy.sh 
    [[ "${PROJECT_VERSION}" != "${local_version}" ]] && update_project="1"

    if [[ "${update_global}" == "1" ]] || [[ "${update_user}" == "1" ]] || [[ "${update_project}" == "1" ]]; then
      update_config
    fi

    # Reload environment variables, from global > user > project
    source "${deployPath}"/deploy.conf
    source ~/.deployrc
    source "${project_config}"

    # Restore workpath value
    WORKPATH="${tmp_workpath}"

    # Trying to continue if global configuration has been changed is buggy
    # if using --current switch
    if [[ "${update_global}" == "1" ]]; then
      console "Global configuration changed - restart your deployment."
      quietExit
    fi
  fi
}

function update_config() {
  empty_line; info "New version (${VERSION}) requires configuration updates."
  if yesno --default yes "Update now? [Y/n] "; then
    [[ "${update_global}" == "1" ]] && update_global
    [[ "${update_user}" == "1" ]] && update_user
    [[ "${update_project}" == "1" ]] && update_project
    info "Updates complete."; empty_line
  else
    info "Skipping update."
  fi
}

function update_global() {
  info "Updating ${deployPath}/deploy.conf..."
  env_settings=(CLEARSCREEN WORKPATH CONFIGDIR SERVERCHECK ACTIVECHECK \
    CHECKTIME REPOHOST SMARTCOMMIT GITSTATS STASH GARBAGE WPCLI WFCHECK \
    FIXPERMISSIONS DEVUSER DEVGROUP APACHEUSER APACHEGROUP FIXINDEX \
    MAILPATH TO FROM SUBJECT EMAILERROR EMAILSUCCESS EMAILQUIT SHORTEMAIL \
    EMAILHTML HTMLTEMPLATE FROMDOMAIN FROMUSER POSTEMAILHEAD POSTEMAILTAIL \
    POSTTOSLACK SLACKURL SLACKERROR POSTURL NOPHP INCOGNITO REMOTELOG \
    REMOTEURL REMOTETEMPLATE SCPPOST SCPUSER SCPHOST SCPHOSTPATH SCPPORT \
    SCPPASS LOCALHOSTPOST LOCALHOSTPATH EXPIRELOGS NIKTO NIKTO_CONFIG)

  if [[ ! -w "${deployPath}" ]]; then
    info "Requesting sudo access..."
    sudo cp "${deployPath}"/deploy.conf "${deployPath}"/deploy.conf.bak
  else
    cp "${deployPath}"/deploy.conf "${deployPath}"/deploy.conf.bak
  fi
  info "Global configuration backup created at ${deployPath}/deploy.conf.bak"
  
  cp "${deployPath}"/deploy-example.conf "${trshFile}"

  # Reload global values
  source "${deployPath}"/deploy.conf
  
  # Loops through the variables
  for i in "${env_settings[@]}" ; do
    current_setting=$(grep "^${i}=" "${deployPath}"/deploy.conf.bak)
    insert_values
  done

  # Install new files
  env_cleanup
  if [[ ! -w "${deployPath}" ]]; then
    sudo cp "${trshFile}" "${deployPath}"/deploy.conf
  else
    cp "${trshFile}" "${deployPath}"/deploy.conf
  fi
}

function update_user() {
  info "Updating ~/.deployrc..."
  env_settings=(CLEARSCREEN VERBOSE GITSTATS)
  
  info "User configuration backup created at ~/.deployrc.bak"
  cp ~/.deployrc ~/.deployrc.bak
  cp "${deployPath}"/.deployrc "${trshFile}"

  # Reload user values
  source ~/.deployrc

  # Loops through the variables
  for i in "${env_settings[@]}" ; do
    current_setting=$(grep "^${i}=" ~/.deployrc)
    insert_values
  done

  # Install new files
  env_cleanup
  cp "${trshFile}" ~/.deployrc
}

function update_project() { 
  info "Updating ${project_config}..."
  env_settings=(PROJNAME PROJCLIENT DEVURL PRODURL REPOHOST REPO MASTER \
    PRODUCTION AUTOMERGE STASH CHECKBRANCH NOKEY DISABLESSHCHECK COMMITMSG \
    WPROOT WPAPP WPSYSTEM DONOTUPDATEWP ACFKEY DEPLOY REQUIREAPPROVAL \
    DONOTDEPLOY TASK TASKUSER ADDTIME POSTTOSLACK SLACKURL SLACKERROR \
    DIGESTSLACK POSTURL TO HTMLTEMPLATE CLIENTLOGO COVER INCOGNITO REMOTELOG \
    REMOTEURL REMOTETEMPLATE SCPPOST SCPUSER SCPHOST SCPHOSTPATH SCPPORT\
    SCPPASS LOCALHOSTPOST LOCALHOSTPATH DIGESTEMAIL CLIENTCONTACT \
    INCLUDEHOSTING IN_HOST IN_TOKEN IN_CLIENT_ID IN_PRODUCT IN_ITEM_COST \
    IN_ITEM_QTY IN_NOTES CLIENTID CLIENTSECRET REDIRECTURI AUTHORIZATIONCODE \
    ACCESSTOKEN REFRESHTOKEN PROFILEID MONITORURL MONITORUSER MONITORPASS \
    SERVERID NIKTO NIKTO_CONFIG STAGING_DEPLOY_PATH PRODUCTION_DEPLOY_HOST \
    PRODUCTION_DEPLOY_PATH SCP_DEPLOY_USER SCP_DEPLOY_PASS SCP_DEPLOY_PORT)

  info "Project configuration backup created at ${project_config}.bak"
  cp "${project_config}" "${project_config}.bak"
  cp "${deployPath}"/deploy.sh "${trshFile}"
  # Loops through the variables
  for i in "${env_settings[@]}" ; do
    current_setting=$(grep "^${i}=" "${project_config}")
    insert_values
  done

  # Install new files
  env_cleanup
  cp "${trshFile}" "${project_config}"
}

function insert_values() {
  if [[ -n "${!i:-}" ]]; then
    [[ "${INCOGNITO}" != "1" ]] && trace "${i}: ${!i}"
    sed_hack=$(echo "sed -i 's^{{${i}}}^${!i}^g' ${trshFile}; sed -i 's^# ${i}^${i}^g' ${trshFile}")
    # Kludgy but works. Ugh.
    eval "${sed_hack}"
  fi
}

function env_cleanup() {
  sed -i "s^{{.*}}^^g" "${trshFile}"
}
