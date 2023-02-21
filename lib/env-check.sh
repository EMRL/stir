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
  tmp_WORK_PATH default_etc updates_skipped)
init_loop

function env_check() {
  # Only check when someone is at the console
  if [[ "${FORCE}" != "1" ]]; then
    # Save the WORK_PATH to reload after this process; this is to allow a 
    # deployment using to --current switch to continue properly after a global
    # configuration file update
    tmp_WORK_PATH="${WORK_PATH}"

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

    # Restore WORK_PATH value
    WORK_PATH="${tmp_WORK_PATH}"

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
    if [[ "${SWITCHES}" != "1" ]]; then
      warning "Cannot be updated while running with command line options."
      info "Try running 'stir ${APP}'"
      quiet_exit
  fi
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
  if [[ ! -w "${stir_path}/global.conf" ]]; then
    info "Requesting sudo access..."
    sudo cp "${stir_path}"/global.conf "${stir_path}"/global.conf.bak
  else
    cp "${stir_path}"/global.conf "${stir_path}"/global.conf.bak
  fi  
  cp "${stir_path}"/stir-global.conf "${trash_file}"
  info "Global configuration backup created at ${stir_path}/global.conf.bak"

  env_settings=(CLEAR_SCREEN WORK_PATH CONFIG_DIR CHECK_SERVER CHECK_ACTIVE \
    CHECK_TIME REPO_HOST SMART_COMMIT GIT_STATS STASH GARBAGE WP_CLI WF_CHECK \
    TO FROM SUBJECT EMAIL_ERROR EMAIL_SUCCESS EMAIL_QUIT SHORT_EMAIL \
    EMAIL_HTML HTML_TEMPLATE FROM_DOMAIN FROM_USER POST_EMAIL_HEAD POST_EMAIL_TAIL \
    POST_TO_SLACK SLACK_URL SLACK_ERROR POST_URL NO_PHP TERSE INCOGNITO REMOTE_LOG \
    REMOTE_URL REMOTE_TEMPLATE SCP_POST SCP_USER SCP_HOST SCP_HOST_PATH SCP_PORT \
    SCP_PASS POST_TO_LOCAL_HOST LOCAL_HOST_PATH EXPIRE_LOGS DB_API_TOKEN NEWS_URL \
    IN_HOST IN_TOKEN IN_OFFSET BUGSNAG_AUTH USE_SMTP CONFIG_BACKUP \
    GRAVITY_FORMS_LICENSE ACF_KEY ACTIVATE_PLUGINS)

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

  cp ~/.stirrc ~/.stirrc.bak
  cp "${stir_path}"/stir-user.rc "${trash_file}"
  info "User configuration backup created at ~/.stirrc.bak"
  i="${trash_file}"
  migrate_variables

  env_settings=(CLEAR_SCREEN VERBOSE GIT_STATS)

  # Loops through the variables
  for i in "${env_settings[@]}" ; do
    current_setting=$(grep -a "^${i}=" ~/.stirrc)
    insert_values
  done

  # Install new files
  env_cleanup
  cp "${trash_file}" ~/.stirrc
  
  console "User configuration updated - restart stir to continue."
  quiet_exit
}

function update_project() { 
  i="${project_config}"
  migrate_variables

  info "Updating ${project_config}..."
  cp "${project_config}" "${project_config}.bak"
  cp "${stir_path}"/stir-project.sh "${trash_file}"
  info "Project configuration backup created at ${project_config}.bak"

  env_settings=(PROJECT_NAME PROJECT_CLIENT DEV_URL PROD_URL REPO_HOST REPO MASTER \
    STAGING PRODUCTION AUTOMERGE STASH CHECK_BRANCH NO_KEY DISABLE_SSH_CHECK \
    commit_message WP_ROOT WP_APP WP_SYSTEM DO_NOT_UPDATE_WP ACF_KEY DEPLOY \
    REQUIRE_APPROVAL DO_NOT_DEPLOY TASK TASK_USER ADD_TIME POST_TO_SLACK SLACK_URL \
    SLACK_ERROR DIGEST_SLACK POST_URL TO HTML_TEMPLATE CLIENT_LOGO COVER \
    INCOGNITO REMOTE_LOG REMOTE_URL REMOTE_TEMPLATE SCP_POST SCP_USER SCP_HOST \
    SCP_HOST_PATH SCP_PORT SCP_PASS POST_TO_LOCAL_HOST LOCAL_HOST_PATH DIGEST_EMAIL \
    CLIENT_CONTACT INCLUDE_HOSTING IN_CLIENT_ID IN_PRODUCT IN_ITEM_COST \
    IN_ITEM_QTY IN_NOTES IN_INCLUDE_REPORT IN_EMAIL CLIENT_ID CLIENT_SECRET \
    REDIRECT_URI AUTHORIZATION_CODE ACCESS_TOKEN REFRESH_TOKEN PROFILE_ID \
    MONITOR_URL MONITOR_USER MONITOR_PASS SERVER_ID NIKTO NIKTO_CONFIG \
    STAGING_DEPLOY_PATH PRODUCTION_DEPLOY_HOST PRODUCTION_DEPLOY_PATH \
    SCP_DEPLOY_USER SCP_DEPLOY_PASS SCP_DEPLOY_PORT NIKTO NIKTO_CONFIG \
    NIKTO_PROXY DB_BACKUP_PATH PREPARE PREPARE_CONFIG ACF_LOCK STAGING \
    GRAVITY_FORMS_LICENSE INCLUDE_DETAILS MAUTIC_URL MAUTIC_AUTH \
    MAUTIC_LEGACY_VERSION SKIP_GIT NEWS_URL ACF_COMPOSER WP_CLI_PATH \
    COMPOSER_CLI_PATH ACTIVATE_PLUGINS)

  # Loops through the variables
  for i in "${env_settings[@]}" ; do
    current_setting=$(grep -a "^${i}=" "${project_config}")
    insert_values
  done

  # Install new files
  env_cleanup
  cp "${trash_file}" "${project_config}"

  console "Project configuration updated - restart stir to continue."
  quiet_exit
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


