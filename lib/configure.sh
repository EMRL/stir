#!/usr/bin/env bash
#
# configure.sh
#
###############################################################################
# Global, user, and project configuration
###############################################################################
trace "Loading configuration"

# Initialize variables
read -r active_files <<< ""
echo "${active_files}" > /dev/null

function configure_project() {
  trace "This is an empty function"
}

function configure_user() {
  empty_line
  arg="CLEARSCREEN"
  if yesno --default yes "Clear screen on startup? [Y/n] "; then
    set_value
  else
    unset_value
  fi

  arg="VERBOSE"
  if yesno --default no "Always show verbose output on console? [y/N] "; then
    set_value
  else
    unset_value
  fi  

  arg="GITSTATS"
  if yesno --default yes "Display project statistics after every deployment? [Y/n] "; then
    set_value
  else
    unset_value
  fi
  [[ "${VERBOSE}" == "TRUE" ]] && VERBOSE="1"; empty_line
}

function configure_global() {
  trace "This is an empty function"
}

function set_value() {
  sed -i -e "s^{{${arg}}}^TRUE^g" \
    -e "s^# ${arg}^${arg}^g" \
    ~/.deployrc      
}

function unset_value() {
  sed -i -e "s^{{${arg}}}^FALSE^g" ~/.deployrc      
}

function clear_user() {
settings=(CLEARSCREEN VERBOSE GITSTATS)
empty_line
for arg in "${settings[@]}" ; do
  unset_value
done
}
