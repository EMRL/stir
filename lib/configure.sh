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

  # Repohost
  remote_origin="$(git ls-remote --get-url)"
  REPOHOST=$(echo ${remote_origin%/*})
  arg="${REPOHOST}"; read -rp "Repo root URL (including http:// or https://):" -e -i "${arg}" value; set_value "${value}"

  # Repo name
  REPO="$(basename -s .git `git config --get remote.origin.url`)"
  arg="${REPO}"; read -rp "Repo name:" -e -i "${arg}" value; set_value "${value}"

  # Branch name
  MASTER="$(git rev-parse --abbrev-ref HEAD)"
  arg="${MASTER}"; read -rp "Master branch name:" -e -i "${arg}" value; set_value "${value}"

  # Project name
  if [[ -z "${PROJNAME}" ]]; then
    PROJNAME="$(basename `git rev-parse --show-toplevel`)"
  fi
  arg="${PROJNAME}"; read -rp "Project name:" -e -i "${arg} " value; set_value "${value}"
  #arg="${PROJCLIENT}"; read -rp "Client name:" -e -i "${arg} " value; set_value "${value}"

  #arg="${DEVURL}"; read -rp "Staging URL (including http:// or https://)" -e -i "${arg}" value; set_value "${value}"
  #arg="${PRODURL}"; read -rp "Production URL (including http:// or https://)" -e -i "${arg}" value; set_value "${value}"
}

function configure_user() {
  empty_line
  config_file="$HOME/.stirrc"
  arg="CLEARSCREEN"
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

  arg="GITSTATS"
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
settings=(CLEARSCREEN VERBOSE GITSTATS)
empty_line
for arg in "${settings[@]}" ; do
  unset_value
done
}
