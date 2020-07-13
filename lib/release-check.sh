#!/usr/bin/env bash
#
# release-check.sh
#
###############################################################################
# Check to see if there is a new release version on Github
###############################################################################

# Initialize variables
var=(release release_notes release_url)
init_loop

function release_check() {
  # Only check for a newer release when someone is at the console
  if [[ "${FORCE}" != "1" ]]; then
    # Get the release tag
    trace "Checking for updates..."
    release="$(${curl_cmd} -s https://api.github.com/repos/emrl/stir/releases/latest | grep \"tag_name\")"
    # Remove the extra garbage
    release="${release#*v}"
    release="$(printf '%s' "${release}" | sed 's/",//g')"

    # Compare versions
    if version_compare "${release}" "${VERSION}"; then
      # Get release notes
      release_notes="$(${curl_cmd} -s https://api.github.com/repos/emrl/stir/releases/latest | grep \"body\")"
      # Remove the extra garbage
      release_notes="$(printf '%s' "${release_notes}" | sed 's^\"body\": \"^^g')"
      release_notes="${release_notes//\"}"
      release_notes=${release_notes#"  "}

      # User feedback
      info "\r\nNew release found: ${release}\r\n"
      printf "${release_notes}" | fold --spaces -w 78; empty_line
      # Update?
      empty_line
      if yesno --default yes "Would you like to update now? [Y/n] "; then
        # Get latest
        release_url="$(${curl_cmd} -s https://api.github.com/repos/emrl/stir/releases/latest | grep tarball_url | cut -d '"' -f 4)"
        
        # Update!
        update_release
        console "Update complete."
        quiet_exit
      fi
    fi
  fi
}

function version_compare() {
  test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"; 
}

# Get latest version and install globally
function update_release() {
  release_url="$(${curl_cmd} -s https://api.github.com/repos/emrl/stir/releases/latest | grep tarball_url | cut -d '"' -f 4)"

  # If user is not root, warn them
  if [[ "${EUID}" -ne "0" ]]; then
    if yesno --default yes "You will be need sudo access to update, continue? [Y/n] "; then
      sudo sleep 1
    else
      console "Installation canceled."; quiet_exit
    fi
  fi
  
  # Continue installation
  "${curl_cmd}" -Ls "${release_url}" -o "/tmp/stir-${release}.tar.gz"
  mkdir /tmp/stir; tar zxvf /tmp/stir-${release}.tar.gz --strip-components=1 -C /tmp/stir
  cd /tmp/stir; sudo install/doinst.sh
  
  # Clean up our mess
  rm -f tar zxvf stir-${release}.tar.gz; rm -rf /tmp/stir
}
