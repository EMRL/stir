#!/usr/bin/env bash
#
# validate.sh
#
###############################################################################
# Check project's variables for special characters that may cause issues
###############################################################################

function validate_conf() {
  # Check URLs
  for var in "${REPOHOST} ${CLIENTLOGO}" "${DEVURL}" "${PRODURL}"; do
    if [[ -n "${var}" ]]; then
      if [[ "${var}" != *"http"*"://"* ]]; then
        error "The URL in your configuration ($var) must be preceded by either http:// or https:// - check your setup."
      fi
    fi
  done

  # Check for bogus characters
  array=( "${PROJNAME}" "${PROJCLIENT}" )
  for i in "${array[@]}"
  do
    if [ `expr "$i" : ".*[!@#\$%^\&*()_+].*"` -gt 0 ]; then 
      warning "Problem with value: ${i}\nCheck your project configuration and remove any special characters [!@#\$%^\&*()_+] from the value above."; quiet_exit 
    fi
  done
}
