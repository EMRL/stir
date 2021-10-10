#!/usr/bin/env bash
#
# doinst.sh
#
###############################################################################
# Installation and configuration
#
# https://github.com/EMRL/stir
###############################################################################

# Set mode
set -uo pipefail

# Initialize variables 
read -r OS VER EXITCODE dependencies option message fg_green fg_red fg_yellow \
  reset YES NO NOT i k WORK_PATH FIRSTRUN INPUTPATH TIMEOUT <<< ""
echo "${OS} ${VER} ${EXITCODE} ${dependencies} ${option} ${message} ${fg_green} 
  ${fg_red} ${reset} ${YES} ${NO} ${NOT} ${i} ${k} ${WORK_PATH} 
  ${FIRSTRUN} ${INPUTPATH}" > /dev/null

# No root, no fun
if [[ "${EUID}" -ne 0 ]]; then
  echo "You must have root access to install - try 'sudo install/doinst.sh'" 2>&1
  exit 1
fi

if [[ $# != "0" ]]; then
  if [[ "${1}" == "--unit-test" ]]; then
    TIMEOUT="TRUE"
  fi
fi

function check_os() {
  # Try to discover the OS flavor 
  if [[ -f /etc/os-release ]]; then
    # freedesktop.org and systemd 
    # shellcheck disable=SC1091
    . /etc/os-release
    OS="${NAME}"
    VER="${VERSION_ID}"
  elif type lsb_release >/dev/null 2>&1; then
    # linuxbase.org
    OS="$(lsb_release -si)"
    VER="$(lsb_release -sr)"
  elif [[ -f /etc/lsb-release ]]; then
    # For some versions of Debian/Ubuntu without lsb_release command
    # shellcheck disable=SC1091
    . /etc/lsb-release
    OS="${DISTRIB_ID}"
    VER="${DISTRIB_RELEASE}"
  elif [[ -f /etc/debian_version ]]; then
    # Older Debian/Ubuntu/etc.
    OS=Debian
    VER="$(cat /etc/debian_version)"
  elif [[ -f /etc/SuSe-release ]]; then
    # Older SuSE/etc.
    ...
  elif [[ -f /etc/redhat-release ]]; then
    # Older Red Hat, CentOS, etc.
    ...
  else
    # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
    OS="$(uname -s)"
    VER="$(uname -r)"
  fi
}

function check_program() {
  printf "%-40s" "Checking for ${1}..."; read -p "" -t 0.03
  # There's potential for non-global stuff to fail this check so here's a
  # fairly kludgey way to hopefully allow those to pass
  if [[ "${1}" =~ ^(wp|grunt|npm)$ ]]; then
    which $(type -p "${1}") >/dev/null 2>&1 && echo "${YES}" || { echo "${NOT}"; message+="${1} "; }
  else
    command -v "${1}" >/dev/null 2>&1 && echo "${YES}" || { echo "${NOT}"; message+="${1} "; }
  fi
}

function error_check() {
  EXITCODE=$?; 
  if [[ "${EXITCODE}" != "0" ]]; then 
    echo "Error ${EXITCODE}: stir not installed."
    exit "${EXITCODE}"
  fi
}

echo; check_os
if [[ -n "${OS}" ]] && [[ -n "${VER}" ]]; then
  echo "${fg_yellow}=> Checking operating system:${reset}"; sleep .3
  echo "${OS} ${VER}"; sleep 1
else
  # No values, crash out for now
  exit 1
fi

# Declare dependencies
dependencies=(awk cat curl echo eval git grep pkill printf read sed sleep tee \
  tput)

# Declare optional stuff
options=(cal gitchart gnuplot grunt npm scp sendmail ssh sshpass ssmtp unzip \
  wget wkhtmltopdf wp xmlstarlet)

message=''
fg_red="$(tput setaf 1)"
fg_green="$(tput setaf 2)"
fg_yellow="$(tput setaf 3)"
reset="$(tput sgr0)"

# Common messages
YES="${fg_green}OK${reset}"
NO="${fg_red}NO${reset}"
NOT="${fg_red}NOT FOUND${reset}"

echo; echo "${fg_yellow}=> Checking for required dependencies:${reset}"
for i in "${dependencies[@]}" ; do
  check_program "${i}"
done

if [[ -n "${message}" ]] ; then
  echo "${fg_red}ERROR: Install missing dependencies and retry installation${reset}"
  exit 1
fi

echo; echo "${fg_yellow}=> Checking optional dependencies:${reset}"
for k in "${options[@]}" ; do
  check_program "${k}"
done

if [[ -n "${message}" ]] ; then
  echo "${fg_red}WARNING: Some extended functionality may not be available${reset}"
  # echo ${message};
fi

# Start the install
echo; sleep 1
if [[ ! -d /etc/stir ]]; then
  echo "Creating directories"
  sudo mkdir /etc/stir; error_check
fi

# Clean out old libraries
if [[ -d /etc/stir/lib ]]; then
  sudo rm /etc/stir/lib/*; error_check
fi

echo "Installing system files"
sudo cp -R etc/* /etc/stir; error_check
sudo cp etc/stir-user.rc /etc/stir; error_check

if [[ ! -f /etc/stir/global.conf ]]; then
  echo "Global configuration not found, installing."
  FIRSTRUN="TRUE"
  sudo cp /etc/stir/stir-global.conf /etc/stir/global.conf; error_check
fi

if [[ ! -f "/etc/stir/html/default/theme.conf" ]]; then
  sudo cp "/etc/stir/html/default/theme-example.conf" "/etc/stir/html/default/theme.conf"
fi

cp -R lib /etc/stir || error_check
cp stir.sh /usr/local/bin/stir || error_check
cp etc/extras/bulk.stir.sh /usr/local/bin/bulk.stir || error_check
sudo chmod 755 /usr/local/bin/stir || error_check
sudo chmod 755 /usr/local/bin/bulk.stir || error_check

# Check for a needed migration
if grep -aq "WORKPATH" "/etc/stir/global.conf"; then
  echo "Done."
  echo; echo "${fg_red}#### IMPORTANT CHANGES ####${reset}"
  echo "Some variable names in configuration files have changed, and Stir will "
  echo "not launch until your configuration is updated. See below. "
  echo
  echo "1. Global configuration files must be migrated manually by using "
  echo "   a one-time command"
  echo "2. Project and user configuration files will be migrated as part of "
  echo "   the upgrade install and will need no extra user interaction "
  echo

  # Get user authorization
  if [[ "${TIMEOUT}" != "TRUE" ]]; then
    read -rp "${fg_yellow}=> Type ${reset}YES${fg_yellow} to migrate your configuration:${reset} " MIGRATE
    if [[ "${MIGRATE}" == "YES" ]]; then 
      if [[ -x "$(command -v stir)" ]]; then
        stir_cmd="$(which stir)"
        sudo "${stir_cmd}" --migrate
      else
        echo "Problem with automatic migration"
        echo "Try running 'sudo stir --migrate' from your shell prompt"
        exit 1
      fi
    else
      echo "You must type YES (case-sensitive) to migrate, no changes made."
    fi
  fi
  exit 0
fi

if [[ "${FIRSTRUN}" == "TRUE" ]]; then
  echo
  echo "${fg_yellow}     _   _"     
  echo " ___| |_(_)_ __" 
  echo "/ __| __| | '__|"
  echo "\__ \ |_| | |"  
  echo "|___/\__|_|_|${reset}"
  echo
  echo "Stir was created to speed and automate maintaining Wordpress websites "
  echo "in an agency environment, with an emphasis on client communication and "
  echo "generating revenue. "
  echo
  echo "Here's a few things that stir can help you do:"
  echo
  echo "1. Schedule automatic updates and deployment of Wordpress plugins and "
  echo "   system files"
  echo "2. Keep clients up to date with simple dashboards and scheduled digest "
  echo "   emails notifying them of their code updates"
  echo "3. Get paid! Track all changes internally w/ integration into project "
  echo "   management, time tracking, and invoicing systems"
  echo "4. Notify your clients and team of updates through Slack and email"
  echo "5. Solve deployment issues with verbose logging features"
  echo
  echo "Let's get your configuration started!"

  # If values need to be set, ask the user for input to setup global.conf
  #
  # WORK_PATH
  if grep -q "{{WORK_PATH}}" "/etc/stir/global.conf"; then
    if [[ "${TIMEOUT}" != "TRUE" ]]; then
      WORK_PATH="/etc/stir/repos/"
      echo; echo "${fg_yellow}=> Where are all (or most) of your repos stored?${reset}" 
      read -rp "[ Ex. ${WORK_PATH} ]: " -e -i "${WORK_PATH}" INPUTPATH
      WORK_PATH="${INPUTPATH:-$WORK_PATH}"
      if [[ -d "${WORK_PATH}" ]]; then
        if [[ -n "$(find ${WORK_PATH} -type d -exec test -e '{}/.git' ';' -print -prune)" ]]; then
          echo "Found git repos at ${WORK_PATH} and using it as your default stir path"
        else
          echo "Using ${WORK_PATH} as your default stir path."
        fi
      else
        if [[ -w ${WORK_PATH} ]]; then
          mkdir "${WORK_PATH}"; error_check
          [[ -d "${WORK_PATH}" ]] && echo "Created ${WORK_PATH} and using it as your default stir path."
        else
          echo "Can not create ${WORK_PATH}"
          exit 1
        fi
      fi
    else
      WORK_PATH="$(cd -P .. && pwd -P)"
    fi
    sed_hack=$(echo "sed -i 's^{{WORK_PATH}}^${WORK_PATH}^g' /etc/stir/global.conf; sed -i 's^# WORK_PATH^WORK_PATH^g' /etc/stir/global.conf"); eval "${sed_hack}"
  fi

  # REPO_HOST
  if grep -q "{{REPO_HOST}}" "/etc/stir/global.conf"; then
    if [[ "${TIMEOUT}" != "TRUE" ]]; then
      REPO_HOST="http://github.com/username/"
      echo; echo "${fg_yellow}=> What is the URL where are all (or most) of your repos hosted?${reset}"
      #echo "Enter the URL for your repository hosting, normally https://REPO_HOST.com/username/"
      read -rp "[ Ex. ${REPO_HOST} ]: " -e -i "${REPO_HOST}" INPUTPATH
      REPO_HOST="${INPUTPATH:-$REPO_HOST}"
    else
      # This is for automated unit testing
      REPO_HOST="http://github.com/emrl/"
    fi
    sed_hack=$(echo "sed -i 's^{{REPO_HOST}}^${REPO_HOST}^g' /etc/stir/global.conf; sed -i 's^# REPO_HOST^REPO_HOST^g' /etc/stir/global.conf"); eval "${sed_hack}"
  fi

  # Additional configuration stuff will go here
  echo
  echo "Learn about configuring Stir at https://github.com/EMRL/stir/wiki"
fi

echo "Successfully installed, try typing 'stir' for help."
exit 0
