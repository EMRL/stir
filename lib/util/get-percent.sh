#!/usr/bin/env bash
#
# get-percent.sh

################################################################################
# get_percent()
#   Get percentage
#
# Arguments:
#   [total]   Total quantity
#   [items]   Number from which to derive percent
#
# Example use:
#   get_percent 80 37
#   VARIABLE="$(get_percent "${var1}" "${var2}")"
#
# Returns:
#   Rounded percentage as an integer
###############################################################################

get_percent() {
  local total="${1:-}"
  local items="${2:-}"

  if [[ -z "${total}" ]] || [[ -z "${items}" ]]; then
    return 1
  fi

  if ! [[ "${total}" =~ ^[0-9]+([.][0-9]+)?$ ]] ||
     ! [[ "${items}" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    return 1
  fi

  if [[ "${total}" == "0" ]]; then
    printf '0\n'
    return 0
  fi

  awk -v total="${total}" -v items="${items}" \
    'BEGIN { printf "%.0f\n", 100 * items / total }'
}
