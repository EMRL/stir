#!/usr/bin/env bash
#
# wp-acf.sh
#
###############################################################################
# Handle ACF Pro updates in more reliable way than wp-cli
###############################################################################

# Declare needed variables
var=(acf_file acf_update_complete)
init_loop

function acf_update() {
  acf_file="/tmp/acfpro.zip"
  trace "Updating ACF Pro "
	
	# Download the ACF Pro upgrade file
	"${wget_cmd}" --header="Accept: application/zip" --user-agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10.8; rv:21.0) Gecko/20100101 Firefox/21.0" -O "${acf_file}" "http://connect.advancedcustomfields.com/index.php?p=pro&a=download&k=${ACF_KEY}" &>> "${log_file}"; error_check

	# Check file integrity
	acf_filecheck

	# Proceed with install
	eval "${wp_cmd}" plugin delete --no-color advanced-custom-fields-pro &>> "${log_file}"; error_check
	eval "${wp_cmd}" plugin install --no-color "${acf_file}" &>> "${log_file}"; error_check
	
	# Housekeeping
	rm "${acf_file}"
	acf_update_complete="1"
}

function acf_filecheck() {
	if [[ -f "${acf_file}" ]]; then
		hash unzip 2>/dev/null || {
			if [[ "${AUTOMATE}" == "1" ]]; then
				warning "Can not find unzip command, skipping ACF file integrity check."; return
			else
				error "Can not find unzip command, ACF file integrity can not be checked."
			fi
		  }

		# Run the check
		unzip -t "${acf_file}" &>/dev/null; error_check
	fi
}