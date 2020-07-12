#!/usr/bin/env bash
#
# post-integration.sh
#
###############################################################################
# Handles integration with other services
###############################################################################

# Compile commit message with other stuff for integration
function build_log() {
  if [[ "${DIGEST}" != "1" ]]; then 
    # OK let's grab the short version of the commit hash
    COMMITHASH="$(git rev-parse --short HEAD)"; 

    # Create commit URL
    if [[ "${REPOHOST}" == *"bitbucket"* ]]; then
      COMMITURL="${REPOHOST}/${REPO}/commits/${COMMITHASH}"
    elif [[ "${REPOHOST}" == *"github"* ]]; then
      COMMITURL="${REPOHOST}/${REPO}/commit/${COMMITHASH}"
    fi

    # Is this a publish only?
    if [[ "${PUBLISH}" == "1" ]] && [[ -z "${notes}" ]]; then 
      notes="Published to production and marked as deployed"
    fi

    # Is this just an approval?
    if [[ "${APPROVE}" == "1" ]] && [[ -z "${notes}" ]]; then
      notes="Marked as approved and deployed" 
    fi

    echo "<strong>Commit ${COMMITHASH}</strong>: ${notes}" > "${postFile}"
  fi
}

# Post integration via email
function mailPost() {
  # If this is an outstanding approval, don't post
  if [[ "${REQUIREAPPROVAL}" == "TRUE" ]] && [[ "${APPROVE}" != "1" ]] && [[ "${DIGEST}" != "1" ]]; then
    trace "Approval required, skipping integration"
  else

    if [[ ! -f "${sendmail_cmd}" ]]; then
      empty_line; warning "Mail system misconfigured or not found, skipping email integration."
      return
    fi

    echo "${COMMITURL}" >> "${postFile}"
    post=$(<"${postFile}")
    (
    # Is this an automated deployment?
    if [ "${AUTOMATE}" = "1" ]; then
      # Is the project configured to log task time
      if [[ -z "${TASKUSER}" ]] || [[ -z "${ADDTIME}" ]]; then
        echo "From: ${FROM}"
      else
        echo "From: ${TASKUSER}"
        echo "Subject: ${ADDTIME}"
      fi
    else
      # If not an automated deployment, use address from .deployrc, or current user email address
      if [[ -n "${FROMUSER}" ]]; then
        echo "From: ${FROMUSER}@${FROMDOMAIN}"
      else
        echo "From: ${USER}@${FROMDOMAIN}"
      fi
      # If deployment happened with the --time switch active, add time to subject line
      if [[ -n "${TIME}" ]] && [[ -n "${ADDTIME}" ]]; then
        echo "Subject: ${ADDTIME}"
      fi
    fi
    echo "To: ${POSTEMAIL}"
    echo "Content-Type: text/plain"
    echo
    echo "${post}";
    ) | "${sendmail_cmd}" -t
  fi
}

function postCommit() {
  # Run Wordpress database updates
  if [[ -n "${PRODUCTION}" ]] && [[ -n "${PRODURL}" ]]; then
    info "Updating production database..."
    "${curl_cmd}" --silent "${PRODURL}${WPSYSTEM}"/wp-admin/upgrade.php?step=1 >/dev/null 2>&1
    # In case curl is being weird
    "${wget_cmd}" -q -O - "${PRODURL}${WPSYSTEM}"/wp-admin/upgrade.php?step=1 > /dev/null 2>&1
  fi

  # Check for a Wordpress core update, update production database if needed
  #if [[ "${UPDCORE}" == "1" ]] && [[ -n "${PRODUCTION}" ]] && [[ -n "${PRODURL}" ]] && [[ -n "${DEPLOY}" ]]; then
  #  info "Upgrading production database..."; curl --silent "${PRODURL}${WPSYSTEM}"/wp-admin/upgrade.php?step=1 >/dev/null 2>&1
  #fi

  # Just for yuks, display git stats for this user (user can override this if it annoys them)
  git_stats

  # Check to see if there's an email integration setup
  if [[ -n "${POSTEMAIL}" ]]; then
    # Is it a valid email address? Ghetto check but better than nothing
    if [[ "${POSTEMAIL}" == ?*@?*.?* ]]; then
      build_log; mailPost
    else
      trace "Integration email address ${POSTEMAIL} does not look valid"
    fi
  fi
}
