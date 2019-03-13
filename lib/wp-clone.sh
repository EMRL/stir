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

function wp_clone() {
  # This is all under construction
  # Get paths
  wp_path
  wp_tmp

  # Create SSH string
  SSH_REPO="${REPOHOST}/${REPO}.git"
  SSH_REPO=$(sed -e "s^.org/^.org:^g" <<< ${SSH_REPO})
  SSH_REPO=$(sed -e "s^https://^git@^g" <<< ${SSH_REPO})

  # Double check in case of insecure repo host
  if [[ "${SSH_REPO}" == *"http"* ]]; then
    SSH_REPO=$(sed -e "s^http://^git@^g" <<< ${SSH_REPO})
  fi

  # Try to make sure ssh will work
  ssh_check
  
  notice "Setting up project..."
  cd ${WORKPATH}; \
  if [[ -d "${WORKPATH}/${REPO}" ]]; then
    cd "${WORKPATH}/${REPO}"; \
    "${git_cmd}" checkout "${MASTER}" &>> /dev/null; error_check
  else
    trace status "Cloning ${SSH_REPO}... "
    "${git_cmd}" clone "${SSH_REPO}" &>> /dev/null; error_check
    trace notime "OK"
  fi

  # Copy plugins that are not part of repo (for update checking)
  # cp -nrp "${WP_PATH}/plugins" "${WP_TMP}/" &>> "${logFile}";

  # Reset our root working directory
  APP_PATH="${WORKPATH}/${REPO}"
  cd "${APP_PATH}"

  # Setup environment variables
  create_env
  WP_PATH="${WP_TMP}"
  ACTIVECHECK="FALSE"
  cd "${WP_PATH}"

  # Create database
  if [[ -z "${PREPARE_CONFIG}" ]]; then
    error "MYSQL user info not found, can not create database."
  else
    # This is temporary
    source "${PREPARE_CONFIG}"

    # If using .env
    if [[ "${env_file}" == *".env" ]]; then
      sed -i -e "/DB_DATABASE/c\DB_DATABASE='null_${REPO}'" \
        -e "/DB_USERNAME/c\DB_USERNAME='${MYSQL_USER}'" \
        -e "/DB_PASSWORD/c\DB_PASSWORD='${MYSQL_PASS}'" \
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

    # Composer stuff
    if [[ -f "${APP_PATH}/composer.json" ]]; then
      cd "${APP_PATH}"
      ${composer_cmd} install; error_check
    fi
    
    # Database check (check is not working correctly)
    # trace "Checking for database \'${DB_DATABASE}\'"
    # "${mysqlshow_cmd}" --user=${MYSQL_USER} --password=${MYSQL_PASS} ${DB_DATABASE} 2> /dev/null
    # DB_CHECK=$?;
    # if [[ "${DB_CHECK}" != "0" ]]; then
       trace status "Creating database... "
    #  "${wp_cmd}" db create &>> /dev/null; error_check; trace notime "OK"
      "${wp_cmd}" db create &>> /dev/null; trace notime "OK"

    #fi

    # Install wordpress database tables
    trace status "Installing Wordpress... "
    "${wp_cmd}" core install --url=null.com --title=Nullsite --admin_user=null --admin_email=null@null.com &>> /dev/null; error_check
    trace notime "OK"

    # Check server
    wp_server_check
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
      cp "${arg}" "${dest}" &>> "${logFile}"
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