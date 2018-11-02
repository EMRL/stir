#!/usr/bin/env bash
#
# wp-clone.sh
#
###############################################################################
# Checks for Wordpress upgrades, and executes upgrades if needed
###############################################################################

# Initialize variables
var=(SSH_REPO TMP_PATH SET_ENV)
init_loop

function wp_clone() {
  # This is all under construction
  trace "Cloning the project..."

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
  cd /tmp; \
  git clone "${SSH_REPO}" #&>> /dev/null &
  #spinner $!

  # Copy plugins that are not part of repo (for update checking)
  cp -nrp "${WP_PATH}/plugins" "${WP_TMP}/" &>> "${logFile}";

  # Reset our root working directory
  APP_PATH="/tmp/${REPO}"
  cd "${APP_PATH}"

  # Get environment variables
  get_env
  WP_PATH="${WP_TMP}"
}

function get_env() {
  env_file=(config/env.php env.php .env.php .env public/wp-settings.php)
  for arg in "${env_file[@]}"; do
    if [[ -f "${WORKPATH}/${APP}/${arg}" ]]; then
      cp "${WORKPATH}/${APP}/${arg}" "/tmp/${REPO}/${arg}"
      if [[ -f "/tmp/${REPO}/${arg}" ]]; then
        SET_ENV="1"
      fi
    fi
  done

  if [[ "${SET_ENV}" != "1" ]]; then
    warning "Configuration file not found, can not continue."
    quickExit
  fi

  GARBAGE="FALSE"
}