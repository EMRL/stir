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
    if [[ "${REPO_HOST}" == *"bitbucket"* ]]; then
      COMMITURL="${REPO_HOST}/${REPO}/commits/${COMMITHASH}"
    elif [[ "${REPO_HOST}" == *"github"* ]]; then
      COMMITURL="${REPO_HOST}/${REPO}/commit/${COMMITHASH}"
    fi

    # Is this a publish only?
    if [[ "${PUBLISH}" == "1" ]] && [[ -z "${notes}" ]]; then 
      notes="Published to production and marked as deployed"
    fi

    # Is this just an approval?
    if [[ "${APPROVE}" == "1" ]] && [[ -z "${notes}" ]]; then
      notes="Marked as approved and deployed" 
    fi

    echo "<strong>Commit ${COMMITHASH}</strong>: ${notes}" > "${post_file}"
  fi
}

# Post integration via email
function mail_post() {
  # If this is an outstanding approval, don't post
  if [[ "${REQUIRE_APPROVAL}" == "TRUE" ]] && [[ "${APPROVE}" != "1" ]] && [[ "${DIGEST}" != "1" ]]; then
    trace "Approval required, skipping integration"
  else

    if [[ ! -f "${sendmail_cmd}" ]]; then
      empty_line; warning "Mail system misconfigured or not found, skipping email integration."
      return
    fi

    echo "${COMMITURL}" >> "${post_file}"
    post=$(<"${post_file}")
    (
    # Is this an automated deployment?
    if [ "${AUTOMATE}" = "1" ]; then
      # Is the project configured to log task time
      if [[ -z "${TASK_USER}" ]] || [[ -z "${ADD_TIME}" ]]; then
        echo "From: ${FROM}"
      else
        echo "From: ${TASK_USER}"
        echo "Subject: ${ADD_TIME}"
      fi
    else
      # If not an automated deployment, use address from .deployrc, or current user email address
      if [[ -n "${FROM_USER}" ]]; then
        echo "From: ${FROM_USER}@${FROM_DOMAIN}"
      else
        echo "From: ${USER}@${FROM_DOMAIN}"
      fi
      # If deployment happened with the --time switch active, add time to subject line
      if [[ -n "${TIME}" ]] && [[ -n "${ADD_TIME}" ]]; then
        echo "Subject: ${ADD_TIME}"
      fi
    fi
    echo "To: ${integration_email}"
    echo "Content-Type: text/plain"
    echo
    echo "${post}";
    ) | "${sendmail_cmd}" -t
  fi
}

function postCommit() {
  # Run Wordpress database updates
  if [[ -n "${PRODUCTION}" ]] && [[ -n "${PROD_URL}" ]] && [[ "core_update_complete" == "1" ]]; then
    info "Updating production database..."
    "${curl_cmd}" --silent "${PROD_URL}${WP_SYSTEM}"/wp-admin/upgrade.php?step=1 >/dev/null 2>&1
    # In case curl is being weird
    "${wget_cmd}" -q -O - "${PROD_URL}${WP_SYSTEM}"/wp-admin/upgrade.php?step=1 > /dev/null 2>&1
  fi

  # Just for yuks, display git stats for this user (user can override this if it annoys them)
  git_stats

  # Check to see if there's an email integration setup
  if [[ -n "${integration_email}" ]]; then
    # Is it a valid email address? Ghetto check but better than nothing
    if [[ "${integration_email}" == ?*@?*.?* ]]; then
      build_log; mail_post
    else
      trace "Integration email address ${integration_email} does not look valid"
    fi
  fi
}
