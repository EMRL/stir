#!/usr/bin/env bash
#
# config-check.sh
#
###############################################################################
# Check to see if configuration files need to be updated, and update if so
###############################################################################

# Initialize variables
var=(update_global update_user update_project env_settings project_config \
  sed_hack short_version global_project_version local_version \
  tmp_workpath default_etc updates_skipped)
init_loop

function env_check() {
  # Only check when someone is at the console
  if [[ "${FORCE}" != "1" ]]; then
    # Save the workpath to reload after this process; this is to allow a 
    # deployment using to --current switch to continue properly after a global
    # configuration file update
    tmp_workpath="${WORKPATH}"

    # Trim alpha/beta part of version number   
    local_version="${VERSION//-*}"
    
    # Check for global vs local install
    if [[ "${stir_path}" != "/etc/stir" ]]; then
      default_etc="${stir_path}/etc"
    else
      default_etc="${stir_path}"
    fi

    # Compare version numbers
    local_version="${GLOBAL_VERSION}"; source "${default_etc}"/stir-global.conf
    [[ "${GLOBAL_VERSION}" != "${local_version}" ]] && update_global="1";
    
    local_version="${USER_VERSION}"; source "${default_etc}"/stir-user.rc
    [[ "${USER_VERSION}" != "${local_version}" ]] && update_user="1";
    
    local_version="${PROJECT_VERSION}"; source "${default_etc}"/stir-project.sh 
    [[ "${PROJECT_VERSION}" != "${local_version}" ]] && update_project="1"

    if [[ "${update_global}" == "1" ]] || [[ "${update_user}" == "1" ]] || [[ "${update_project}" == "1" ]]; then
      update_config
    fi

    # Reload environment variables, from global > user > project
    source "${etc_path}"
    source ~/.stirrc
    
    # TODO This probably needs more thought
    if [[ -r "${project_config}" ]]; then
      source "${project_config}"
    else
      console "Project configuration has changed or is missing - restart stir to continue."
      quiet_exit
    fi

    # Restore workpath value
    WORKPATH="${tmp_workpath}"

    # Trying to continue if global configuration has been changed is buggy
    # if using --current switch
    #if [[ "${update_global}" == "1" ]] && [[ "${updates_skipped}" != "1" ]]; then
    #  console "Global configuration updated - restart stir to continue."
    #  quiet_exit
    #fi
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
    updates_skipped="1"
    info "Skipping update."
  fi
}

function update_global() {
  info "Updating ${stir_path}/global.conf..."
  env_settings=(CLEARSCREEN WORKPATH CONFIGDIR SERVERCHECK ACTIVECHECK \
    CHECKTIME REPOHOST SMARTCOMMIT GITSTATS STASH GARBAGE WPCLI WFCHECK \
    TO FROM SUBJECT EMAILERROR EMAILSUCCESS EMAILQUIT SHORTEMAIL \
    EMAILHTML HTMLTEMPLATE FROMDOMAIN FROMUSER POSTEMAILHEAD POSTEMAILTAIL \
    POSTTOSLACK SLACKURL SLACKERROR POSTURL NOPHP TERSE INCOGNITO REMOTELOG \
    REMOTEURL REMOTETEMPLATE SCPPOST SCPUSER SCPHOST SCPHOSTPATH SCPPORT \
    SCPPASS LOCALHOSTPOST LOCALHOSTPATH EXPIRELOGS DB_API_TOKEN NEWS_URL \
    IN_HOST IN_TOKEN IN_OFFSET BUGSNAG_AUTH USE_SMTP CONFIG_BACKUP \
    GRAVITY_FORMS_LICENSE ACFKEY)

  if [[ ! -w "${stir_path}/global.conf" ]]; then
    info "Requesting sudo access..."
    sudo cp "${stir_path}"/global.conf "${stir_path}"/global.conf.bak
  else
    cp "${stir_path}"/global.conf "${stir_path}"/global.conf.bak
  fi
  info "Global configuration backup created at ${stir_path}/global.conf.bak"
  
  cp "${stir_path}"/stir-global.conf "${trash_file}"

  # Reload global values
  source "${stir_path}"/global.conf
  
  # Loops through the variables
  for i in "${env_settings[@]}" ; do
    current_setting=$(grep -a "^${i}=" "${stir_path}"/global.conf.bak)
    insert_values
  done

  # Install new files
  env_cleanup
  if [[ ! -w "${stir_path}/global.conf" ]]; then
    sudo cp "${trash_file}" "${stir_path}"/global.conf
  else
    cp "${trash_file}" "${stir_path}"/global.conf
  fi
  
  console "Global configuration updated - restart stir to continue."
  quiet_exit
}

function update_user() {
  info "Updating ~/.stirrc..."
  env_settings=(CLEARSCREEN VERBOSE GITSTATS)
  
  info "User configuration backup created at ~/.stirrc.bak"
  cp ~/.stirrc ~/.stirrc.bak
  cp "${stir_path}"/stir-user.rc "${trash_file}"

  # Reload user values
  source ~/.stirrc

  # Loops through the variables
  for i in "${env_settings[@]}" ; do
    current_setting=$(grep -a "^${i}=" ~/.stirrc)
    insert_values
  done

  # Install new files
  env_cleanup
  cp "${trash_file}" ~/.stirrc
}

function update_project() { 
  info "Updating ${project_config}..."
  env_settings=(PROJNAME PROJCLIENT DEVURL PRODURL REPOHOST REPO MASTER \
    STAGING PRODUCTION AUTOMERGE STASH CHECKBRANCH NOKEY DISABLESSHCHECK \
    COMMITMSG WPROOT WPAPP WPSYSTEM DONOTUPDATEWP ACFKEY DEPLOY \
    REQUIREAPPROVAL DONOTDEPLOY TASK TASKUSER ADDTIME POSTTOSLACK SLACKURL \
    SLACKERROR DIGESTSLACK POSTURL TO HTMLTEMPLATE CLIENTLOGO COVER \
    INCOGNITO REMOTELOG REMOTEURL REMOTETEMPLATE SCPPOST SCPUSER SCPHOST \
    SCPHOSTPATH SCPPORT SCPPASS LOCALHOSTPOST LOCALHOSTPATH DIGESTEMAIL \
    CLIENTCONTACT INCLUDEHOSTING IN_CLIENT_ID IN_PRODUCT IN_ITEM_COST \
    IN_ITEM_QTY IN_NOTES IN_EMAIL CLIENTID CLIENTSECRET REDIRECTURI \
    AUTHORIZATIONCODE ACCESSTOKEN REFRESHTOKEN PROFILEID MONITORURL \
    MONITORUSER MONITORPASS SERVERID NIKTO NIKTO_CONFIG STAGING_DEPLOY_PATH \
    PRODUCTION_DEPLOY_HOST PRODUCTION_DEPLOY_PATH SCP_DEPLOY_USER \
    SCP_DEPLOY_PASS SCP_DEPLOY_PORT NIKTO NIKTO_CONFIG NIKTO_PROXY \
    DB_BACKUP_PATH PREPARE PREPARE_CONFIG ACF_LOCK STAGING \
    GRAVITY_FORMS_LICENSE)

  info "Project configuration backup created at ${project_config}.bak"
  cp "${project_config}" "${project_config}.bak"
  cp "${stir_path}"/stir-project.sh "${trash_file}"
  # Loops through the variables
  for i in "${env_settings[@]}" ; do
    current_setting=$(grep -a "^${i}=" "${project_config}")
    insert_values
  done

  # Install new files
  env_cleanup
  cp "${trash_file}" "${project_config}"
}

function insert_values() {
  if [[ -n "${!i:-}" ]]; then
    [[ "${INCOGNITO}" != "1" ]] && trace "${i}: ${!i}"
    sed_hack=$(echo "sed -i 's^{{${i}}}^${!i}^g' ${trash_file}; sed -i 's^# ${i}^${i}^g' ${trash_file}")
    # Kludgy but works. Ugh.
    eval "${sed_hack}"
  fi
}

function env_cleanup() {
  sed -i "s^{{.*}}^^g" "${trash_file}"
}


