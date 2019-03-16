#!/usr/bin/env bash
#
# smart-commit.sh
#
###############################################################################
# Tries to create "Smart Commit" messages based on parsing output from wp-cli
###############################################################################

# Constructing smart *cough* commit messages
function smart_commit() {
  if [[ "${SMARTCOMMIT}" == "TRUE" ]]; then
    # Checks for the existence of a successful plugin update, using grep, and if 
    # we find updates, grab the relevant line of text from the logs
    # Looks like this changed somehow, new version of wp-cli maybe?
    # PCA=$(grep '\<Success: Updated' "${logFile}" | grep 'plugins')
 
    PCA=$("${wc_cmd}" -l < "${wpFile}")
    
    #if [[ -z "${PCA}" ]] && [[ -n "${ACFKEY}" ]]; then
    #  if grep -q "${ACFKEY}" "${logFile}"; then
    #    PCA="1"
    #  fi
    #fi

    if [[ "${PCA}" -gt "0" ]] || [[ ! -z "${UPDCORE}" ]] || [[ -s "${wpFile}" ]]; then
      trace "Building commit message"

      if [[ "${PCA}" == "0" ]] && [[ -z "${ACFFILE}" ]]; then
        trace "No plugin updates"
      else
        # How many plugins have we updated? First, strip out the Success:
        # PCB=$(echo "${PCA}" | sed 's/^.*\(Updated.*\)/\1/g')
        # Strips the last period, makes my head hurt.
        # PCC=${PCB%?}; PCD=$(echo $PCB | cut -c 1-$(expr `echo "$PCC" | wc -c` - 2))
        # PCC=$(echo "${PCB}" | tr -d .)
        # Get this thing ready; first remove the leading spaces 
        awk '{print $1, $2}' "${wpFile}" > "${trshFile}" && mv "${trshFile}" "${wpFile}";
        # Add commas between the plugins with this
        sed ':a;N;$!ba;s/\n/, /g' "${wpFile}" > "${trshFile}" && mv "${trshFile}" "${wpFile}";
        # Replace current commit message with plugin update info 
        PLUGINS=$(<"${wpFile}")

        if [[ "${PCA}" -gt "1" ]]; then
          COMMITMSG="Updated ${PCA} plugins ($PLUGINS)"
        else
          COMMITMSG="Updated ${PCA} plugin ($PLUGINS)"
        fi
      fi

      # Is this an ACF-only update?
      #if [[ "${PCA}" == "1" ]]; then
      #  trace "Creating ACF commit message"
      #  PCC="Updated 1 of 1 plugin"
      #  PLUGINS="advanced-custom-fields-pro"
      #  COMMITMSG="$PCC ($PLUGINS)"
      #fi

      # So what about a Wordpress core update?
      if [[ $UPDCORE == "1" ]]; then
        if [[ -z "$PCC" ]]; then 
          COMMITMSG="Updated system (wp-core $COREUPD)"
        else
          COMMITMSG="Updated plugins ($PLUGINS) and system (wp-core $COREUPD)"
        fi
      else      
        trace "No system updates"
      fi

      # Output the contents of $COMMITMSG
      if [[ -n "${COMMITMSG}" ]]; then
        trace "Auto-generated commit message: $COMMITMSG"
      fi
    fi
  fi
}
