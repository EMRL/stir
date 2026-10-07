#!/usr/bin/env bash
#
# clean-path.sh

################################################################################
# clean_path()
#   Strip extra forward slashes in URL or path directory values
#
# Arguments:
#   [path]         Input path or URL   
#
# Returns:
#   ${clean_path}  The post-precessed URL
#
# Example use:
#   clean_path path
############################################################################### 
clean_path() {
  if [[ -n "${1}" ]]; then
    declare arg1="${1}"
    cleaned_path="$(echo ${arg1} | tr -s /)"
    # "${2}"=$(sed -i "s^//^/^g" "${1}")
    cleaned_path="$(echo ${cleaned_path} | sed -e 's#:/#://#g')"
  fi 
}
