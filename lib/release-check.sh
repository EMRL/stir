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
    release="$(curl -s https://api.github.com/repos/emrl/stir/releases/latest | grep \"tag_name\")"
    # Remove the extra garbage
    release="${release#*v}"
    release="$(printf '%s' "${release}" | sed 's/",//g')"

    # Compare versions
    if version_compare "${release}" "${VERSION}"; then
      # Get release notes
      release_notes="$(curl -s https://api.github.com/repos/emrl/stir/releases/latest | grep \"body\")"
      # Remove the extra garbage
      release_notes="$(printf '%s' "${release_notes}" | sed 's^\"body\": \"^^g')"
      release_notes="${release_notes//\"}"
      release_notes=${release_notes#"  "}

      # User feedback
      info "\r\nNew release found: ${release}\r\n"
      printf "${release_notes}" | fold --spaces -w 78; empty_line
      # Update?
      empty_line
      if yesno --default yes "Would you like to download now? [Y/n] "; then
        # Get latest
        release_url="$(curl -s https://api.github.com/repos/emrl/stir/releases/latest | grep tarball_url | cut -d '"' -f 4)"
        curl -Ls "${release_url}" -o "stir-${release}.tar.gz"
        # Eventually I'll have a full install here but for now we'll bail
        console "Try 'tar zxvf stir-${release}.tar.gz' and then 'sudo doinst.sh' from the archive root directory."
        quietExit
      fi
    fi
  fi
}

function version_compare() {
  test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"; 
}
