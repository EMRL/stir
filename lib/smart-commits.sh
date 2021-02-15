#!/usr/bin/env bash
#
# smart-commit.sh
#
###############################################################################
# Tries to create "Smart Commit" messages based on parsing output from wp-cli
###############################################################################

# Constructing smart *cough* commit messages
function smart_commit() {
  if [[ "${SMART_COMMIT}" == "TRUE" ]]; then 
    PCA=$("${wc_cmd}" -l < "${wp_file}")

    if [[ "${UPDATE_ACF}" == "1" ]]; then
      PCA=$((PCA+1))
    fi

    if [[ "${PCA}" -gt "0" ]] || [[ ! -z "${UPDCORE}" ]] || [[ -s "${wp_file}" ]]; then
      trace "Building commit message"

      if [[ "${PCA}" == "0" ]] && [[ -z "${acf_file}" ]]; then
        trace "No plugin updates"
      else
        # Get this thing ready; first remove the leading spaces 
        awk '{print $1, $2}' "${wp_file}" > "${trash_file}" && mv "${trash_file}" "${wp_file}";
        # Add commas between the plugins with this
        sed ':a;N;$!ba;s/\n/, /g' "${wp_file}" > "${trash_file}" && mv "${trash_file}" "${wp_file}";
        # Replace current commit message with plugin update info 
        PLUGINS=$(<"${wp_file}")

        # This whole thing is just so ugly
        if [[ "${UPDATE_ACF}" == "1" ]]; then
          PLUGINS="advanced-custom-fields-pro"
        fi

        if [[ "${PCA}" -gt "1" ]]; then
          COMMIT_MSG="Updated ${PCA} plugins ($PLUGINS)"
        elif [[ "${PCA}" == "1" ]]; then
          COMMIT_MSG="Updated ${PCA} plugin ($PLUGINS)"
        fi
      fi

      # So what about a Wordpress core update?
      if [[ $UPDCORE == "1" ]]; then
        # if [[ -z "$PCC" ]]; then 
        if [[ -z "${PLUGINS}" ]]; then
          COMMIT_MSG="Updated system (wp-core ${COREUPD})"
        else
          COMMIT_MSG="${COMMIT_MSG} and system (wp-core ${COREUPD})"
        fi
      else      
        trace "No system updates"
      fi

      # Output the contents of $COMMIT_MSG
      if [[ -n "${COMMIT_MSG}" ]]; then
        trace "Auto-generated commit message: ${COMMIT_MSG}"
      fi
    fi
  fi
}
