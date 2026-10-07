#!/usr/bin/env bash
#
# is-integer.sh

###############################################################################
# is_integer()
#   Check whether a value contains only numeric integer characters
#
# Arguments:
#   [value]   Value to check
#
# Returns:
#   Sets ${integer_check} to:
#     0       Value is an integer
#     1       Value is not an integer
#
# Example use:
#   is_integer "${value}"
#   if [[ "${integer_check}" == "0" ]]; then
#     echo "Value is an integer"
#   fi
###############################################################################
is_integer() {
  declare arg1="${1}"; integer_check="0"
  if [[ ! "${arg1}" =~ ^[0-9]+$ ]]; then
    integer_check="1"
  fi
}
