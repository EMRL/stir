#!/usr/bin/env bash
#
# smart-commit.sh
#
###############################################################################
# Tries to create "Smart Commit" messages based on parsing output from wp-cli
###############################################################################

# Initialize variables
var=(commit_message plugins_updated plugin_list)
init_loop

# Constructing smart *cough* commit messages
function smart_commit() {
  if [[ "${SMART_COMMIT}" == "TRUE" ]]; then 
    plugins_updated=$("${wc_cmd}" -l < "${wp_file}")

    if [[ "${plugin_update_complete}" == "0" ]]; then
      trace "No plugin updates"
    else
      # Get this thing ready; first remove the leading spaces 
      awk '{print $1, $2}' "${wp_file}" > "${trash_file}" && mv "${trash_file}" "${wp_file}"
      # Add commas between the plugins with this
      sed -i ':a;N;$!ba;s/\n/, /g' "${wp_file}"
      # Replace current commit message with plugin update info 
      plugin_list=$(<"${wp_file}")

      if [[ "${plugins_updated}" -gt "0" ]]; then
        commit_message="Updated ${plugins_updated} plugins ($plugin_list)"
      elif [[ "${plugins_updated}" == "1" ]]; then
        commit_message="Updated ${plugins_updated} plugin ($plugin_list)"
      fi
    fi

    # So what about a Wordpress core update?
    if [[ "${core_update_complete}" == "1" ]]; then
      if [[ -z "${commit_message}" ]]; then
        commit_message="Updated system (wp-core ${core_update_version})"
      else
        commit_message="${commit_message} and system (wp-core ${core_update_version})"
      fi
    else      
      trace "No system updates"
    fi

    # Check if composer failed on first try, but worked while updating plugins
    #if [[ "${core_update_attempt}" == "1" ]]; then
    #  core_current_version=(eval "${wp_cmd}" core version)
    #  if [[ "${core_update_version}" == "${core_current_version}" ]]; then
    #    # Build the appropiate smart commit message
    #    core_update_complete="1"
    #    if [[ "${plugin_update_complete}" == "1" ]]; then
    #      commit_message="${commit_message} and system (wp-core ${core_update_version})"
    #    else
    #      commit_message="Updated system (wp-core ${core_update_version})"
    #    fi
    #  fi

    # Output the contents of $commit_message
    if [[ -n "${commit_message}" ]]; then
      trace "Auto-generated commit message: ${commit_message}"
    fi
  fi
}
