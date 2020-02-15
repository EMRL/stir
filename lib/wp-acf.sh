#!/usr/bin/env bash
#
# wp-acf.sh
#
###############################################################################
# Handle ACF Pro updates in more reliable way than wp-cli
###############################################################################

# Declare needed variables
var=(ACFFILE)
init_loop

function acf_update() {
  if grep -aq "advanced-custom-fields-pro" "${wpFile}"; then
	ACFFILE="/tmp/acfpro.zip"
	# Download the ACF Pro upgrade file
	wget --header="Accept: application/zip" --user-agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10.8; rv:21.0) Gecko/20100101 Firefox/21.0" -O "${ACFFILE}" "http://connect.advancedcustomfields.com/index.php?p=pro&a=download&k=${ACFKEY}" &>> "${logFile}"; error_check

	# Check file integrity
	acf_filecheck

	# Proceed with install
	"${wp_cmd}" plugin delete --no-color advanced-custom-fields-pro &>> "${logFile}"
	"${wp_cmd}" plugin install --no-color "${ACFFILE}" &>> "${logFile}"
	rm "${ACFFILE}"
  fi
}

function acf_filecheck() {
	if [[ -f "${ACFFILE}" ]]; then
		hash unzip 2>/dev/null || {
			if [[ "${AUTOMATE}" == "1" ]]; then
				warning "Can not find unzip command, skipping ACF file integrity check."; return
			else
				error "Can not find unzip command, ACF file integrity can not be checked."
			fi
		  }

		# Run the check
		unzip -t "${ACFFILE}" &>/dev/null; error_check
	fi
}