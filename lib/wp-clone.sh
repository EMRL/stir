#!/usr/bin/env bash
#
# wp-clone.sh
#
###############################################################################
# Checks for Wordpress upgrades, and executes upgrades if needed
###############################################################################

# Initialize variables
var=(SSH_REPO TMP_PATH SET_ENV dest REMOVE_ME MYSQL_USER MYSQL_PASS \
  DB_CHECK)
init_loop

function wp_clone_handler() {
  "${git_cmd}" clone --no-checkout "${SSH_REPO}" "${WORK_PATH}/${APP}/${REPO}" &>> /dev/null; error_check
  cd "${WORK_PATH}/${APP}/${REPO}"
  "${git_cmd}" branch --track origin/"${MASTER}" &>> /dev/null; error_check
  if [[ -n "${STAGING}" ]]; then   
    "${git_cmd}" branch --track origin/"${STAGING}" &>> /dev/null; error_check
  fi
  if [[ -n "${PRODUCTION}" ]]; then
      "${git_cmd}" branch --track origin/"${PRODUCTION}" &>> /dev/null; error_check
  fi
  cd "${WORK_PATH}/${APP}"
  mv "${WORK_PATH}/${APP}/${REPO}/.git" "${WORK_PATH}/${APP}"  &>> /dev/null; error_check 
  rm -rf "${WORK_PATH}/${APP}/${REPO}"  &>> /dev/null; error_check
  "${git_cmd}" reset --hard HEAD &>> /dev/null; error_check 
}

function check_mysql_service() {
  if [[ -z "$(pgrep mysql)" ]]; then 
    warning "MySQL service not found, can not continue."
    quiet_exit
  fi
}

function wp_clone() {
  # Chill for a sec
  sleep 2
  
  # This is all under construction
  check_mysql_service

  # Get paths
  wp_path
  wp_tmp

  # Create SSH string
  SSH_REPO="${REPO_HOST}/${REPO}.git"
  SSH_REPO=$(sed -e "s^.org/^.org:^g" <<< ${SSH_REPO})
  SSH_REPO=$(sed -e "s^https://^git@^g" <<< ${SSH_REPO})

  # Double check in case of insecure repo host
  if [[ "${SSH_REPO}" == *"http"* ]]; then
    SSH_REPO=$(sed -e "s^http://^git@^g" <<< ${SSH_REPO})
  fi

  # Try to make sure ssh will work
  ssh_check
  
  notice "Setting up project..."
  cd "${WORK_PATH}/${APP}"; \
  if [[ -d "${WORK_PATH}/${APP}/.gitignore" ]]; then
    "${git_cmd}" checkout "${MASTER}" &>> /dev/null; error_check
  else
    trace "Cloning ${SSH_REPO}... "
    wp_clone_handler &
    spinner $!
    trace "OK"
  fi

  # Copy plugins that are not part of repo (for update checking)
  # cp -nrp "${WP_PATH}/plugins" "${WP_TMP}/" &>> "${log_file}";

  # Reset our root working directory
  # APP_PATH="${WORK_PATH}/${REPO}"
  cd "${APP_PATH}"

  # Setup environment variables
  create_env
  CHECK_ACTIVE="FALSE"

  # Create database
  if [[ -z "${PREPARE_CONFIG}" ]]; then
    error "MYSQL user info not found, can not create database."
  else
    # This is temporary
    source "${PREPARE_CONFIG}"

    # TODO: Make these bits a proper loop, this is fugly

    # If using .env
    if [[ "${env_file}" == *".env" ]]; then
      sed -i -e "/DB_DATABASE/c\DB_DATABASE='null_${REPO}'" \
        -e "/DB_USERNAME/c\DB_USERNAME='${MYSQL_USER}'" \
        -e "/DB_PASSWORD/c\DB_PASSWORD='${MYSQL_PASS}'" \
        -e "/WP_SECURE_AUTH_KEY/c\WP_SECURE_AUTH_KEY='null_key'" \
        -e "/GRAVITY_FORMS_LICENSE/c\GRAVITY_FORMS_LICENSE='${GRAVITY_FORMS_LICENSE}'" \
        -e "/EVENTS_CALENDAR_PRO_LICENSE/c\EVENTS_CALENDAR_PRO_LICENSE='${EVENTS_CALENDAR_PRO_LICENSE}'" \
        -e "/WP_AUTH_KEY/c\WP_AUTH_KEY='null_key'" \
        -e "/WP_LOGGED_IN_KEY/c\WP_LOGGED_IN_KEY='null_key'" \
        -e "/WP_NONCE_KEY/c\WP_NONCE_KEY='null_key'" \
        -e "/WP_SECURE_AUTH_SALT/c\WP_SECURE_AUTH_SALT='null_salt'" \
        -e "/WP_AUTH_SALT/c\WP_AUTH_SALT='null_salt'" \
        -e "/WP_LOGGED_IN_SALT/c\WP_LOGGED_IN_SALT='null_salt'" \
        -e "/WP_NONCE_SALT/c\WP_NONCE_SALT='null_salt'" \
        -e "/SECURE_AUTH_KEY/c\SECURE_AUTH_KEY='null_key'" \
        -e "/AUTH_KEY/c\AUTH_KEY='null_key'" \
        -e "/LOGGED_IN_KEY/c\LOGGED_IN_KEY='null_key'" \
        -e "/NONCE_KEY/c\NONCE_KEY='null_key'" \
        -e "/SECURE_AUTH_SALT/c\SECURE_AUTH_SALT='null_salt'" \
        -e "/AUTH_SALT/c\AUTH_SALT='null_salt'" \
        -e "/LOGGED_IN_SALT/c\LOGGED_IN_SALT='null_salt'" \
        -e "/NONCE_SALT/c\NONCE_SALT='null_salt'" \
        "${APP_PATH}/${env_file}"
    fi

    # If using env.php config
    if [[ "${env_file}" == *"env.php"* ]]; then
      sed -i -e "/host/c\'host' => 'localhost'," \
        -e "/name/c\'name' => 'null_${REPO}'," \
        -e "/user/c\'user' => '${MYSQL_USER}'," \
        -e "/pass/c\'pass' => '${MYSQL_PASS}'," \
        "${APP_PATH}/${env_file}"
    fi

    # If using a standard wp-config.php
    if [[ "${env_file}" == *"wp-config.php"* ]]; then
      sed -i -e "s^localhost^localhost^g" \
        -e "s^database_name_here^null_${REPO}^g" \
        -e "s^username_here^${MYSQL_USER}^g" \
        -e "s^password_here^${MYSQL_PASS}^g" \
        "${APP_PATH}/${env_file}"
    fi

    # Set Gravityforms license if needed
    if [[ -n "${GRAVITY_FORMS_LICENSE}" ]]; then
      sed -i "/GRAVITY_FORMS_LICENSE/c\GRAVITY_FORMS_LICENSE='${GRAVITY_FORMS_LICENSE}'" \
        "${APP_PATH}/${env_file}"
    fi

    source "${APP_PATH}/${env_file}"

    # Composer stuff
    if [[ -f "${APP_PATH}/composer.json" ]]; then
      cd "${APP_PATH}"
      eval "${composer_cmd}" install; error_check
    fi
    
    # Database check (check is not working correctly)
    # trace "Checking for database \'${DB_DATABASE}\'"
    # "${mysqlshow_cmd}" --user=${MYSQL_USER} --password=${MYSQL_PASS} ${DB_DATABASE} 2> /dev/null
    # DB_CHECK=$?;
    # if [[ "${DB_CHECK}" != "0" ]]; then
    if [[ -n "${wp_cmd}" ]]; then
      eval "${wp_cmd}" db check  > /dev/null 2>&1
      EXITCODE=$?; 
      if [[ "${EXITCODE}" -eq "0" ]]; then
        info "Dropping Wordpress database..."
        eval "${wp_cmd}" db drop --yes
      fi
    fi
    trace status "Creating database... "
    error_detail="Unable to create database"
      eval "${wp_cmd}" db create &>> /dev/null; error_check; 
      # Insert wp db check here
      trace notime "OK"
    #fi

    # Install wordpress database tables
    eval "${wp_cmd}" core > /dev/null 2>&1
    EXITCODE=$?; 
    if [[ "${EXITCODE}" -ne "0" ]]; then
      trace status "Installing Wordpress... "
      error_detail="Unable to install Wordpress"
      eval "${wp_cmd}" core install --url=null.com --title=Nullsite --admin_user=null --admin_email=null@null.com &>> /dev/null; error_check
      trace notime "OK"
    fi

    # Check server
    # wp_check_server

    # Activate plugins
    wp_activate_plugin "${ACTIVATE_PLUGINS}"

    #wp_activate_plugin all
    trace "Done."
  fi
}

function create_env() {
  env_file=(config/env-example.php env-example.php .env-example.php \
    .env.example .env.sample public/wp-config-sample.php wp-config-sample.php)
  for arg in "${env_file[@]}"; do
    if [[ -f "${APP_PATH}/${arg}" ]]; then
      if [[ "${arg}" == *"-example"* ]]; then
        REMOVE_ME="-example"
      elif [[ "${arg}" == *"-sample"* ]]; then
        REMOVE_ME="-sample"
      elif [[ "${arg}" == *".sample"* ]]; then
        REMOVE_ME=".sample"
      elif [[ "${arg}" == *".example"* ]]; then
        REMOVE_ME=".example"
      fi
      dest="$(printf '%s\n' ${arg//$REMOVE_ME/})"
      cp "${arg}" "${dest}" &>> "${log_file}"
      SET_ENV="1"
      env_file="${dest}"
    fi
  done

  if [[ "${SET_ENV}" != "1" ]]; then
    error "Configuration file not found, can not continue."
  else
    source "${env_file}"
  fi

  # This is a freshly cloned repo, no need for garbage collection
  GARBAGE="FALSE"
}