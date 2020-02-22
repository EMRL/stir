#!/usr/bin/env bash
# 
# yesno.sh
#
###############################################################################
# A simple Yes/No function
###############################################################################

function yesno() {
  local ans
  local ok=0
  local default
  local t
  if [[ "${UNIT_TEST}" == "1" ]]; then
    local timeout="1"
  else
    local timeout="0"
  fi

  while [[ "${1}" ]]
  do
    case "${1}" in

    --default)
      shift
      default="${1}"
      if [[ ! "${default}" ]]; then error "Missing default value"; fi
      t=$(tr '[:upper:]' '[:lower:]' <<< "${default}")

      if [[ "${t}" != 'y'  &&  "${t}" != 'yes'  &&  "${t}" != 'n'  &&  "${t}" != 'no' ]]; then
        error "Illegal default answer: ${default}"
      fi
      default="${t}"
      shift
      ;;

    --timeout)
      shift
      timeout="${1}"
      if [[ ! "${timeout}" ]]; then error "Missing timeout value"; fi
      if [[ ! "${timeout}" =~ ^[0-9][0-9]*$ ]]; then error "Illegal timeout value: ${timeout}"; fi
      shift
      ;;

    -*)
      error "Unrecognized option: ${1}"
      ;;

    *)
      break
      ;;
    esac
  done

  if [[ "${timeout}" -ne "0"  &&  ! "${default}" ]]; then
    error "Non-zero timeout requires a default answer"
  fi

  if [[ ! "${*}" ]]; then error "Missing question"; fi

  while [[ "${ok}" -eq "0" ]]
  do
    if [[ "${timeout}" -ne "0" ]]; then
      if ! read -rt "${timeout}" -p "$*" ans; then
        ans="${default}"
      else
        # Reset timeout if answer entered.
        timeout="0"
        if [[ ! "${ans}" ]]; then ans="${default}"; fi
      fi
    else
      read -rp "$*" ans
      if [[ ! "${ans}" ]]; then
        ans="${default}"
      else
        ans=$(tr '[:upper:]' '[:lower:]' <<< "${ans}")
      fi 
    fi

    if [[ "${ans}" == 'y'  ||  "${ans}" == 'yes'  ||  "${ans}" == 'n'  ||  "${ans}" == 'no' ]]; then
      ok="1"
    fi

    if [[ "${ok}" -eq "0" ]]; then warning "Valid answers are: yes, y, no, n"; fi
  done
  [[ "${ans}" = "y" || "${ans}" == "yes" ]]
}
