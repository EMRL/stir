#!/usr/bin/env bash
#
# validate.sh
#
###############################################################################
# Check project's variables for special characters that may cause issues
###############################################################################
trace "Loading validation tests"

function validate_conf() {
  array=( "${PROJNAME}" "${PROJCLIENT}" )
  for i in "${array[@]}"
  do
    if [ `expr "$i" : ".*[!@#\$%^\&*()_+].*"` -gt 0 ]; then 
      warning "Problem with value: ${i}\nCheck your project configuration and remove any special characters [!@#\$%^\&*()_+] from the value above."; quietExit 
    fi
  done
}
