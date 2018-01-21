#!/usr/bin/env bash
#
# release-check.sh
#
###############################################################################
# Check to see if there is a new release version on Github
###############################################################################

function release_check() {
  # Only check for a newer release when someone is at the console
  if [[ "${FORCE}" != "1" ]]; then
    # Get the release tag
    trace "Checking for deploy updates..."
    RELEASE="$(curl -s https://api.github.com/repos/emrl/deploy/releases/latest | grep \"tag_name\")"
    # Remove the extra garbage
    RELEASE="${RELEASE#*v}"
    RELEASE="$(printf '%s' "${RELEASE}" | sed 's/",//g')"

    # Compare versions
    if version_compare "${RELEASE}" "${VERSION}"; then
      # Get release notes
      RELEASENOTES="$(curl -s https://api.github.com/repos/emrl/deploy/releases/latest | grep \"body\")"
      # Remove the extra garbage
      RELEASENOTES="$(printf '%s' "${RELEASENOTES}" | sed 's^\"body\": \"^^g')"
      RELEASENOTES="${RELEASENOTES//\"}"
      RELEASENOTES=${RELEASENOTES#"  "}

      # User feedback
      info "\r\nNew release found: ${RELEASE}"
      printf "${RELEASENOTES}" | fold --spaces -w 78; emptyLine
      # Update?
      if yesno --default yes "Would you like to download now? [Y/n] "; then
        # Get latest
        RELEASEURL="$(curl -s https://api.github.com/repos/emrl/deploy/releases/latest | grep tarball_url | cut -d '"' -f 4)"
        curl -Ls "${RELEASEURL}" -o "deploy-${RELEASE}.tar.gz"
        # Eventually I'll have a full install here but for now we'll bail
        console "Try 'tar zxvf deploy-${RELEASE}.tar.gz' and then 'sudo doinst.sh' from the archive root directory."
        quietExit
      fi
    fi
  fi
}

function version_compare() { 
  test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"; 
}
