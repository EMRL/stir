#!/usr/bin/env bash
#
# configure.sh
#
###############################################################################
# Global, user, and project configuration
###############################################################################

# Initialize variables
var=(value remote_origin config_file)
init_loop

function configure_project() {
  # 
  empty_line
  config_file="${APPRC}"

  # REPO_HOST
  remote_origin="$(git ls-remote --get-url)"
  REPO_HOST=$(echo ${remote_origin%/*})
  arg="${REPO_HOST}"; read -rp "Repo root URL (including https://):" -e -i "${arg}" value; set_value "${value}"

  # Repo name
  REPO="$(basename -s .git `git config --get remote.origin.url`)"
  arg="${REPO}"; read -rp "Repo name:" -e -i "${arg}" value; set_value "${value}"

  # Branch name
  MASTER="$(git rev-parse --abbrev-ref HEAD)"
  arg="${MASTER}"; read -rp "Master branch name:" -e -i "${arg}" value; set_value "${value}"

  # Project name
  if [[ -z "${PROJECT_NAME}" ]]; then
    PROJECT_NAME="$(basename `git rev-parse --show-toplevel`)"
  fi
  arg="${PROJECT_NAME}"; read -rp "Project name:" -e -i "${arg} " value; set_value "${value}"
  #arg="${PROJECT_CLIENT}"; read -rp "Client name:" -e -i "${arg} " value; set_value "${value}"

  #arg="${DEV_URL}"; read -rp "Staging URL (including https://)" -e -i "${arg}" value; set_value "${value}"
  #arg="${PROD_URL}"; read -rp "Production URL (including https://)" -e -i "${arg}" value; set_value "${value}"
}

function configure_user() {
  empty_line
  config_file="$HOME/.stirrc"
  arg="CLEAR_SCREEN"
  if yesno --default yes "Clear screen on startup? [Y/n] "; then
    set_value TRUE
  else
    unset_value
  fi

  arg="VERBOSE"
  if yesno --default no "Always show verbose output on console? [y/N] "; then
    set_value TRUE
  else
    unset_value
  fi  

  arg="GIT_STATS"
  if yesno --default yes "Display project statistics after every deployment? [Y/n] "; then
    set_value TRUE
  else
    unset_value
  fi
  [[ "${VERBOSE}" == "TRUE" ]] && VERBOSE="1"; empty_line
}

function configure_global() {
  trace "This is an empty function"
}

function set_value() {
  value="$1"
  sed -i -e "s^{{${arg}}}^${value}^g" \
    -e "s^# ${arg}^${arg}^g" "${config_file}"      
}

function unset_value() {
  sed -i -e "s^{{${arg}}}^FALSE^g" "${config_file}"      
}

function clear_user() {
settings=(CLEAR_SCREEN VERBOSE GIT_STATS)
empty_line
for arg in "${settings[@]}" ; do
  unset_value
done
}
