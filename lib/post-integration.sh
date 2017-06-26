#!/bin/bash
#
# post-integration.sh
#
# Handles integration with other services
trace "Loading integration services"

# Compile commit message with other stuff for integration
function buildLog() {
	if [[ "${DIGEST}" != "1" ]]; then 
		# OK let's grab the short version of the commit hash
		COMMITHASH="$(git rev-parse --short HEAD)"; COMMITURL="${REPOHOST}/${REPO}/commits/${COMMITHASH}"

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
		echo "${COMMITURL}" >> "${postFile}"
		postSendmail=$(<"${postFile}")
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
		echo "${postSendmail}";
		) | "${MAILPATH}"/sendmail -t
	fi
}

function postCommit() {
	# Check for a Wordpress core update, update production database if needed
	if [[ "${UPDCORE}" == "1" ]] && [[ -n "${PRODUCTION}" ]] && [[ -n "${PRODURL}" ]] && [[ -n "${DEPLOY}" ]]; then
		info "Upgrading production database..."; lynx -dump "${PRODURL}"/system/wp-admin/upgrade.php?step=1 > "${trshFile}"
	fi

	# Just for yuks, display git stats for this user (user can override this if it annoys them)
	gitStats

	# Check to see if there's an email integration setup
	if [[ -n "$POSTEMAIL" ]]; then
		# Is it a valid email address? Ghetto check but better than nothing
		if [[ "$POSTEMAIL" == ?*@?*.?* ]]; then
			buildLog; mailPost
		else
			trace "Integration email address ${POSTEMAIL} does not look valid"
		fi
	fi
}
