#!/usr/bin/env bash
#
# validate.sh
#
###############################################################################
# Check project's variables for special characters that may cause issues
###############################################################################

function validate_conf() {
  # Check URLs
  for var in "${REPO_HOST} ${CLIENT_LOGO}" "${DEV_URL}" "${PROD_URL}"; do
    if [[ -n "${var}" ]]; then
      if [[ "${var}" != *"http"*"://"* ]]; then
        error "The URL in your configuration ($var) must be preceded by either https:// - check your setup."
      fi
    fi
  done

  # Check for bogus characters
  array=( "${PROJECT_NAME}" "${PROJECT_CLIENT}" )
  for i in "${array[@]}"
  do
    if [ `expr "$i" : ".*[!@#\$%^\&*()_+].*"` -gt 0 ]; then 
      warning "Problem with value: ${i}\nCheck your project configuration and remove any special characters [!@#\$%^\&*()_+] from the value above."; quiet_exit 
    fi
  done
}
