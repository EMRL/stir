#!/usr/bin/env bash
#
# uninst.sh
#
###############################################################################
# Completely uninstall stir
#
# https://github.com/EMRL/stir
###############################################################################

# Set mode
set -uo pipefail

# Initialize variables 
read -r OS VER EXITCODE dependencies option message fg_green fg_red reset \
  YES NO NOT i k <<< ""
echo "${OS} ${VER} ${EXITCODE} ${dependencies} ${option} ${message} ${fg_green} 
  ${fg_red} ${reset} ${YES} ${NO} ${NOT} ${i} ${k}" > /dev/null

# No root, no fun
if [[ "${EUID}" -ne 0 ]]; then
  echo "You must have root access to uninstall - try 'sudo install/uninst.sh'" 2>&1
  exit 1
fi

function error_check() {
  EXITCODE=$?; 
  if [[ "${EXITCODE}" != "0" ]]; then 
    echo "Error ${EXITCODE}: stir not uninstalled."
    exit "${EXITCODE}"
  fi
}

function yesno() {
  local ans
  local ok=0
  local timeout=0
  local default
  local t

  while [[ "$1" ]]
  do
    case "$1" in

    --default)
      shift
      default=$1
      if [[ ! "$default" ]]; then error "Missing default value"; fi
      t=$(tr '[:upper:]' '[:lower:]' <<< "${default}")

      if [[ "$t" != 'y'  &&  "$t" != 'yes'  &&  "$t" != 'n'  &&  "$t" != 'no' ]]; then
        error "Illegal default answer: $default"
      fi
      default=$t
      shift
      ;;

    --timeout)
      shift
      timeout=$1
      if [[ ! "$timeout" ]]; then error "Missing timeout value"; fi
      if [[ ! "$timeout" =~ ^[0-9][0-9]*$ ]]; then error "Illegal timeout value: $timeout"; fi
      shift
      ;;

    -*)
      error "Unrecognized option: $1"
      ;;

    *)
      break
      ;;
    esac
  done

  if [[ $timeout -ne 0  &&  ! "$default" ]]; then
    error "Non-zero timeout requires a default answer"
  fi

  if [[ ! "$*" ]]; then error "Missing question"; fi

  while [[ $ok -eq 0 ]]
  do
    if [[ "${timeout}" -ne 0 ]]; then
      if ! read -rt "${timeout}" -p "$*" ans; then
        ans=$default
      else
        # Turn off timeout if answer entered.
        timeout=0
        if [[ ! "${ans}" ]]; then ans=$default; fi
      fi
    else
      read -rp "$*" ans
      if [[ ! "${ans}" ]]; then
        ans=$default
      else
        ans=$(tr '[:upper:]' '[:lower:]' <<< "${ans}")
      fi 
    fi

    if [[ "$ans" == 'y'  ||  "$ans" == 'yes'  ||  "$ans" == 'n'  ||  "$ans" == 'no' ]]; then
      ok=1
    fi

    if [[ $ok -eq 0 ]]; then warning "Valid answers are: yes, y, no, n"; fi
  done
  [[ "$ans" = "y" || "$ans" == "yes" ]]
}

# Start the uninstall
echo; sleep 1

if yesno --default yes "Uninstall stir? [Y/n] "; then
  if [[ -f /usr/local/bin/stir ]]; then
    echo "Removing stir"
    sudo rm /usr/local/bin/stir; error_check

    if [[ -d /etc/stir/lib ]]; then
      sudo rm -rf /etc/stir/lib; error_check
    fi

    if [[ -d /etc/stir/html ]]; then
      sudo rm -rf /etc/stir/html; error_check
    fi

    if yesno --default yes "Remove configuration files? [Y/n] "; then
      if [[ -d /etc/stir ]]; then 
        sudo rm -rf /etc/stir; error_check
      fi
    fi
    echo "Successfully uninstalled."
    exit 0
  fi
fi
