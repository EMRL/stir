#!/bin/bash
#
# log-handling.sh
#
# Handles parsing and creating logs
trace "Loading log handling"

function makeLog() {
	# Filter raw log output as configured by user
	if [ "${NOPHP}" == "TRUE" ]; then
		grep -vE "(PHP |Notice:|Warning:|Strict Standards:)" "${logFile}" > "${postFile}"
		cat "${postFile}" > "${logFile}"
	fi

	# Setup a couple of variables
	VIEWPORT="680"
	VIEWPORTPRE=$(expr ${VIEWPORT} - 80)
	LOGURL="${REMOTEURL}/${APP}${COMMITHASH}.html"	

	if [[ -z "${DEVURL}" ]]; then
		DEVURL="N/A"
	fi

	if [[ -z "${PRODURL}" ]]; then
		PRODURL="N/A"
	fi

	# IF we're using HTML emails, let's get to work
	if [[ "${EMAILHTML}" == "TRUE" ]]; then
		htmlBuild
		# Load the email into a variable
		htmlSendmail=$(<"${htmlFile}")
	fi

	# Create HTML/PHP logs for viewing online
	if [[ "${REMOTELOG}" == "TRUE" ]]; then
		# For web logs, VIEWPORT should be 960
		VIEWPORT="960"
		VIEWPORTPRE=$(expr ${VIEWPORT} - 80)
		htmlBuild; postLog
		# Strip out the buttons that self-link
		sed -e "s^BUTTON: BEGIN //-->^${VIEWPORT}^g" -i "${htmlFile}"
	fi
}

function htmlBuild() {
	# Build out the HTML
	if [ "${message_state}" == "ERROR" ]; then
		# Oh man, this is an error
		notes="${error_msg}"
		LOGTITLE="Deployment Error"
		# Create the header
		cat "${deployPath}/html/${EMAILTEMPLATE}/header.html" "${deployPath}/html/${EMAILTEMPLATE}/error.html" > "${htmlFile}"
	else
		# Does this project need to be approved before finalizing deployment?
		if [[ "${REQUIREAPPROVAL}" == "TRUE" ]] && [[ "${APPROVE}" != "1" ]]; then
			message_state="APPROVAL NEEDED"
			LOGTITLE="Deployment Approval"
			cat "${deployPath}/html/${EMAILTEMPLATE}/header.html" "${deployPath}/html/${EMAILTEMPLATE}/approve.html" > "${htmlFile}"
		else
			# Looks like we've got a normal successful deployment
			message_state="SUCCESS"
			# Is this a scheduled updated?
			if [[ "${AUTOMATE}" == "1" ]]; then
				LOGTITLE="Scheduled Deployment"
			else
				LOGTITLE="Deployment Log"
			fi
			cat "${deployPath}/html/${EMAILTEMPLATE}/header.html" "${deployPath}/html/${EMAILTEMPLATE}/success.html" > "${htmlFile}"
		fi
	fi

	# Process the variables before we add the full log because sed
	cat "${htmlFile}" > "${trshFile}"
	processLog

	# Insert the full deployment logfile & button it all up
	cat "${logFile}" "${deployPath}/html/${EMAILTEMPLATE}/footer.html" >> "${htmlFile}"
}

# Filters through html templates to inject our project's variables
function processLog() {
	sed -e "s^{{VIEWPORT}}^${VIEWPORT}^g" \
	 	-e "s^{{NOW}}^${NOW}^g" \
		-e "s^{{DEV}}^${DEV}^g" \
		-e "s^{{LOGTITLE}}^${LOGTITLE}^g" \
		-e "s^{{USER}}^${USER}^g" \
		-e "s^{{PROJNAME}}^${PROJNAME}^g" \
		-e "s^{{PROJCLIENT}}^${PROJCLIENT}^g" \
		-e "s^{{CLIENTLOGO}}^${CLIENTLOGO}^g" \
		-e "s^{{DEVURL}}^${DEVURL}^g" \
		-e "s^{{PRODURL}}^${PRODURL}^g" \
		-e "s^{{COMMITURL}}^${COMMITURL}^g" \
		-e "s^{{EXITCODE}}^${EXITCODE}^g" \
		-e "s^{{COMMITHASH}}^${COMMITHASH}^g" \
		-e "s^{{NOTES}}^${notes}^g" \
		-e "s^{{USER}}^${USER}^g" \
		-e "s^{{LOGURL}}^${LOGURL}^g" \
		-e "s^{{VIEWPORTPRE}}^${VIEWPORTPRE}^g" \
		"${trshFile}" > "${htmlFile}"
}

# Remote log function 
function postLog() {
	if [ "${REMOTELOG}" == "TRUE" ]; then
		# Post to localhost by simply copying files
		if [[ "${LOCALHOSTPOST}" == "TRUE" ]] && [[ -f "${htmlFile}" ]]; then
			cp "${htmlFile}" "${LOCALHOSTPATH}/${APP}${COMMITHASH}.html"
			# Attempt to make sure the files are readable by all
			chmod a+rw "${LOCALHOSTPATH}/${APP}${COMMITHASH}.html" &> /dev/null
			# Remove logs older then X days
			find "${LOCALHOSTPATH}"* -mtime +"${EXPIRELOGS}" -exec rm {} \;
		fi

		# Send the files through SCP (not yet enabled)
		if [ "SCPPOST" == "TRUE" ]; then
			if [ -n "${SCPPASS}" ]; then
				sshpass -p "${SCPPASS}" scp -o StrictHostKeyChecking=no "${htmlFile}" "${SCPUSER}"@"${SCPHOST}":"${SCPHOSTPATH}/${APP}${COMMITHASH}.html" &> /dev/null
			else
				scp "${htmlFile}" "${SCPUSER}"@"${SCPHOST}":"${SCPHOSTPATH}/${APP}{COMMITHASH}.html" &> /dev/null
			fi
		fi
	fi
}

function mailLog() {
	# Only send email if a commit has been made, an approval is required, or there has been an error
	if [[ -n "${COMMITHASH}" ]] || [[ "${message_state}" == "ERROR" ]] || [[ "${message_state}" == "APPROVAL NEEDED" ]]; then
		if [[ "${EMAILHTML}" == "TRUE" ]]; then
			# Send the email
			(
			echo "Sender: ${FROM}"
			echo "From: ${FROM} <${FROM}>"
			echo "Reply-To: ${FROM} <${FROM}>"
			echo "To: ${TO}"
			echo "Subject: [${message_state}] ${SUBJECT} - ${APP}"				
			echo "Content-Type: text/html"
			echo
			echo "${htmlSendmail}";
			) | "${MAILPATH}"/sendmail -t
		else
			# Compile and send text format email
			textSendmail=$(<"${logFile}")
			(
			echo "Sender: ${FROM}"
			echo "From: ${FROM} <${FROM}>"
			echo "Reply-To: ${FROM} <${FROM}>"
			echo "To: ${TO}"
			echo "Subject: [${message_state}] ${SUBJECT} - ${APP}"			
			echo "Content-Type: text/plain"
			echo
			echo "${textSendmail}";
			) | "${MAILPATH}"/sendmail -t
		fi
	fi
}

function emailTest() {
	console "Testing email..."
	if [[ -z "${TO}" ]]; then
		warning "No recipient address found."; emptyLine
		cleanUp; exit 1
	else
		# Send HTML mail
		(
		echo "Sender: ${FROM}"
		echo "From: ${FROM} <${FROM}>"
		echo "Reply-To: ${FROM} <${FROM}>"
		echo "To: ${TO}"
		echo "Subject: [TESTING] ${SUBJECT} - ${APP}"
		echo "Content-Type: text/html"
		echo
		echo "This is a test HTML email from <a href=\"https://github.com/EMRL/deploy/\">deploy ${VERSION}</a>.<br /><br />"
		echo "Current project is ${APP}<br />"
		echo "Current user is ${DEV}";
		) | "${MAILPATH}"/sendmail -t
		# Send Text mail
		(
		echo "Sender: ${FROM}"
		echo "From: ${FROM} <${FROM}>"
		echo "Reply-To: ${FROM} <${FROM}>"
		echo "To: ${TO}"
		echo "Subject: [TESTING] ${SUBJECT} - ${APP}"
		echo "Content-Type: text/plain"
		echo
		echo "This is a test TEXT email from deploy ${VERSION} (https://github.com/EMRL/deploy/)"
		echo
		echo "Current project is ${APP}"
		echo "Current user is ${DEV}";
		) | "${MAILPATH}"/sendmail -t
	fi
}
