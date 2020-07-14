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
  reset YES NO NOT i k WORKPATH FIRSTRUN INPUTPATH TIMEOUT <<< ""
echo "${OS} ${VER} ${EXITCODE} ${dependencies} ${option} ${message} ${fg_green} 
  ${fg_red} ${reset} ${YES} ${NO} ${NOT} ${i} ${k} ${WORKPATH} 
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

if [[ -z "${message}" ]] ; then
  #echo "${fg_green}SUCCESS: System is ready!${reset}"
  sleep 1
else
  echo "${fg_red}ERROR: Install missing dependencies and retry installation${reset}"
  # echo ${message};
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
if [[ ! -d /etc/stir ]]; then # || [[ ! -d /etc/stir/lib ]] || [[ ! -d /etc/stir/crontab ]]; then
  echo "Creating directories"
  if [[ ! -d /etc/stir ]]; then
    sudo mkdir /etc/stir; error_check
  fi
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

if [[ "${FIRSTRUN}" == "TRUE" ]]; then
  # Someday some first run help stuff could go here
  echo
  echo "${fg_yellow}     _   _"     
  echo " ___| |_(_)_ __" 
  echo "/ __| __| | '__|"
  echo "\__ \ |_| | |"  
  echo "|___/\__|_|_|${reset}"
  echo
  echo "welcome to Stir!"
  echo
  echo "Stir is designed to speed up, integrate, and automate project "
  echo "deployment. Its main focus is Wordpress websites, but it can be used "
  echo "with any code repository."
  echo
  echo "Here's a few things that stir can help you do:"
  echo
  echo "1. Schedule automatic updates and deployment of Wordpress plugins and "
  echo "   system files"
  echo "2. Keep clients up to date with simple dashboards and scheduled digest "
  echo "   emails notifying them of their code updates"
  echo "3. Track all changes internally w/ integration into project management, "
  echo "   time tracking, and invoicing systems"
  echo "4. Notify your team of deployments through Slack and emails"
  echo "5. Solve deployment issues with verbose logging features"
  echo
  echo "Let's get your configuration started!"

  # If values need to be set, ask the user for input to setup global.conf
  #
  # WORKPATH
  if grep -q "{{WORKPATH}}" "/etc/stir/global.conf"; then
    if [[ "${TIMEOUT}" != "TRUE" ]]; then
      WORKPATH="/etc/stir/repos/"
      echo; echo "${fg_yellow}=> Where are all (or most) of your repos stored?${reset}" 
      read -rp "[ Ex. ${WORKPATH} ]: " -e -i "${WORKPATH}" INPUTPATH
      WORKPATH="${INPUTPATH:-$WORKPATH}"
      if [[ -d "${WORKPATH}" ]]; then
        if [[ -n "$(find ${WORKPATH} -type d -exec test -e '{}/.git' ';' -print -prune)" ]]; then
          echo "Found git repos at ${WORKPATH} and using it as your default stir path"
        else
          echo "Using ${WORKPATH} as your default stir path."
        fi
      else
        mkdir "${WORKPATH}"; error_check
        [[ -d "${WORKPATH}" ]] && echo "Created ${WORKPATH} and using it as your default stir path."
      fi
    else
      WORKPATH="$(cd -P .. && pwd -P)"
    fi
    sed_hack=$(echo "sed -i 's^{{WORKPATH}}^${WORKPATH}^g' /etc/stir/global.conf; sed -i 's^# WORKPATH^WORKPATH^g' /etc/stir/global.conf"); eval "${sed_hack}"
  fi

  # REPOHOST
  if grep -q "{{REPOHOST}}" "/etc/stir/global.conf"; then
    if [[ "${TIMEOUT}" != "TRUE" ]]; then
      REPOHOST="http://github.com/username/"
      echo; echo "${fg_yellow}=> What is the URL where are all (or most) of your repos hosted?${reset}"
      #echo "Enter the URL for your repository hosting, normally https://repohost.com/username/"
      read -rp "[ Ex. ${REPOHOST} ]: " -e -i "${REPOHOST}" INPUTPATH
      REPOHOST="${INPUTPATH:-$REPOHOST}"
    else
      # This is for automated unit testing
      REPOHOST="http://github.com/emrl/"
    fi
    sed_hack=$(echo "sed -i 's^{{REPOHOST}}^${REPOHOST}^g' /etc/stir/global.conf; sed -i 's^# REPOHOST^REPOHOST^g' /etc/stir/global.conf"); eval "${sed_hack}"
  fi

  # Additional configuration stuff will go here
  echo
  echo "Learn about configuring Stir at https://github.com/EMRL/stir/wiki"
fi

# If automated unit testing, exit now
#if [[ "${TIMEOUT}" == "TRUE" ]]; then
#  exit 0
#fi

# Clean out unused variables
# sed -i 's^{{.*}}^^g' /etc/stir/global.conf

echo "Successfully installed, try typing 'stir' for help."
exit 0
