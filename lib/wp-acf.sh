#!/usr/bin/env bash
#
# wp-acf.sh
#
###############################################################################
# Handle ACF Pro updates in more reliable way than wp-cli
###############################################################################

# Declare needed variables
read -r ACFFILE <<< ""
echo "${ACFFILE}" > /dev/null

function acf_update() {
  if grep -q "advanced-custom-fields-pro" "${wpFile}"; then
    ACFFILE="/tmp/acfpro.zip"
    # Download the ACF Pro upgrade file
    wget -O "${ACFFILE}" "http://connect.advancedcustomfields.com/index.php?p=pro&a=download&k=${ACFKEY}" &>> "${logFile}"
    "${WPCLI}"/wp plugin delete --no-color advanced-custom-fields-pro &>> "${logFile}"
    "${WPCLI}"/wp plugin install --no-color "${ACFFILE}" &>> "${logFile}"
    rm "${ACFFILE}"
  fi
}
