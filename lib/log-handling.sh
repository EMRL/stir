#!/bin/bash
#
# log-handling.sh
#
# Handles parsing and creating logs
trace "Loading log handling"

# Log via email, needs work
function makeLog() {
	# Filter raw log output as configured by user
	if [ "${NOPHP}" == "TRUE" ]; then
		grep -vE "(PHP |Notice:|Warning:|Strict Standards:)" "${logFile}" > "${postFile}"
		cat "${postFile}" > "${logFile}"
	fi

	# Start compiling HTML files if needed
	if [ "${EMAILHTML}" == "TRUE" ] || [ "${REMOTELOG}" == "TRUE" ] || [ "${NOTIFYCLIENT}" == "TRUE" ]; then
		echo "<!--// VARIABLE INPUT //--><p style=\"font-family: Arial, sans-serif; font-style: normal; font-weight: 400; color: #000;\"><strong>Date:</strong> ${NOW}<br /><strong>Project:</strong> ${PROJNAME} (${PROJCLIENT})" > "${trshFile}"

		# If this is a website, display the development/production URLs, otherwise skip them
		if [ -n "${DEVURL}" ]; then
			echo "<br /><strong>Staging:</strong> <a style=\"color: #47ACDF; text-decoration:none; font-weight: bold;\" href=\"${DEVURL}\">${DEVURL}</a>" >> "${trshFile}"
		fi
		if [ -n "${PRODURL}" ]; then
			echo "<br /><strong>Production:</strong> <a style=\"color: #47ACDF; text-decoration:none; font-weight: bold;\" href=\"${PRODURL}\">${PRODURL}</a>" >> "${trshFile}"
		fi
		echo "</p><table style=\"background-color: " >> "${trshFile}"

		# Hopefully clients don't see errors, but if they do, change header color
		if [ "${message_state}" == "ERROR" ]; then
			echo "#CC2233" >> "${trshFile}"
			COMMITURL="#"
		else
			echo "#47ACDF" >> "${trshFile}"
		fi

		echo ";\" border=\"0\" width=\"100%\" cellspacing=\"0\" cellpadding=\"0\" height=\"60\"><tr><td width=\"82\" height=\"82\" style=\"padding-left:20px;\"><div style=\"width: 60px; height: 60px; position: relative; overflow: hidden; -webkit-border-radius: 50%; -moz-border-radius: 50%; -ms-border-radius: 50%; -o-border-radius: 50%; border-radius: 50%;\"><img style=\"display: inline; margin: 0 auto; height: 100%; width: auto;\"" >> "${trshFile}"

		# Check for a client logo
		if [ -n "${CLIENTLOGO}" ]; then
			echo "src=\"${CLIENTLOGO}\"" >> "${trshFile}"
		else
			echo "src=\"https://guestreviewsystem.com/themes/hrs/images/no_logo.gif\"" >> "${trshFile}"
		fi
		echo "alt=\"${PROJNAME}\" title=\"${PROJNAME}\" /></div></td><td><a href=\"${COMMITURL}\" style=\"font-family: Arial, sans-serif; font-style: normal; font-weight: 700; color: #fff; text-decoration: none;\">" >> "${trshFile}"
		
		# Oh geez, more errors
		if [ "${message_state}" == "ERROR" ]; then
			echo "DEPLOYMENT ERROR" >> "${trshFile}"
			notes="${error_msg}"
			COMMITHASH="-ERROR-${RANDOM}"
		else
			echo "Commit #${COMMITHASH}" >> "${trshFile}"
		fi

		echo "</a></td><td align=\"right\" style=\"padding-right: 20px;\">" >> "${trshFile}"

		# Is there a full log posted to the web? If so, include a link
		if [ "${REMOTELOG}" == "TRUE" ] && [ -n "${REMOTEURL}" ]; then
			echo "<a href=\"${REMOTEURL}/${APP}${COMMITHASH}.html\"><img src=\"http://emrl.co/assets/img/open.png\" height=\"32\" width=\"32\" alt=\"Open Details\" title=\"Open Details\" /></a>" >> "${trshFile}"
		fi

		echo "</td></tr><tr><td colspan=\"3\" valign=\"middle\" style=\"background-color: #eee; padding: 20px;\"><p style=\"font-family: Arial, sans-serif; font-style: normal; font-weight: 400; color: #000;\"><strong>Message:</strong> ${notes}</p>" >> "${trshFile}" >> "${trshFile}"

		# Include a "reply" link if there's a task integration for this project
		if [ -n "${POSTEMAILHEAD}" ] || [ -n "${TASK}" ] || [ -n "${POSTEMAILTAIL}" ]; then
			# Change the notification text slightly if we need to	
			if [ "${NOTIFYCLIENT}" == "TRUE" ]; then
				LOGMSG="This was a scheduled update. If you have any comments or questions about the details of this update, "
			else
				LOGMSG="If you have any comments or questions about this update, "
			fi
			echo "<p style=\"font-family: Arial, sans-serif; font-style: normal; color: #000;\">${LOGMSG}<a style=\"color: #47ACDF; text-decoration:none;\" href=\"mailto: ${POSTEMAILHEAD}${TASK}${POSTEMAILTAIL}?subject=Question%20on%20deployment%20${COMMITHASH}\">send them over</a>.</p>" >> "${trshFile}"
		fi
		echo "</td></tr></table>" >> "${trshFile}" 	# Close the report table

		# Compile short client email
		if [ "${NOTIFYCLIENT}" == "TRUE" ]; then
			if [ "${AUTOMATEDONLY}" == "TRUE" ] && [ "${AUTOMATE}" != "1" ]; then
				trace "Skipping client notification"
			else
				# If a commit hash exists and there were no errors, we assume 
				# success and compile and send the client email
				if [ -n "${COMMITHASH}" ] && [ "${message_state}" != "ERROR" ]; then
					cat "${deployPath}/html/${EMAILTEMPLATE}/head-email.html" "${trshFile}" "${deployPath}/html/${EMAILTEMPLATE}/foot.html" > "${clientEmail}"
					# Load the email into a variable
					clientSendmail=$(<"${clientEmail}")
					# Fire up sendmail
					(
					echo "From: ${FROM}"
					echo "To: ${CLIENTEMAIL}"
					echo "Subject: [SUCCESS] ${SUBJECT} - ${APP}"
					echo "Content-Type: text/html"
					echo
					echo "${clientSendmail}";
					) | "${MAILPATH}"/sendmail -t
				fi
			fi
		fi
	fi

	# Remote log function 
	if [ "${REMOTELOG}" == "TRUE" ]; then
		if [ -n "${COMMITHASH}" ] || [ "${message_state}" == "ERROR" ]; then
			# Compile the head, log information, and footer into a single html file
			# cat "${deployPath}/html/${EMAILTEMPLATE}/head-email.html" "${trshFile}" "${logFile}" "${deployPath}/html/${EMAILTEMPLATE}/foot.html" > "${htmlFile}"
			cat "${deployPath}/html/${EMAILTEMPLATE}/head-logfile.html" "${trshFile}" > "${htmlFile}"
			echo "<pre style=\"font: 100% courier,monospace; border: none; overflow: auto; overflow-x: scroll; width: 930px; padding: 0 1em 1em 1em; background: #eee; color: #000;\"><code style=\"font-size: 80%; word-wrap:break-word;\">" >> "${htmlFile}"
			cat "${logFile}" >> "${htmlFile}"
			echo "</code></pre>" >> "${htmlFile}"
			cat "${deployPath}/html/${EMAILTEMPLATE}/foot.html" >> "${htmlFile}"

			# Send the files through SCP (not yet enabled)
			if [ "SCPPOST" == "TRUE" ]; then
				if [ -n "${SCPPASS}" ]; then
					sshpass -p "${SCPPASS}" scp -o StrictHostKeyChecking=no "${htmlFile}" "${SCPUSER}"@"${SCPHOST}":"${SCPHOSTPATH}/${APP}${COMMITHASH}.html" &> /dev/null
				else
					scp "${htmlFile}" "${SCPUSER}"@"${SCPHOST}":"${SCPHOSTPATH}/${APP}{COMMITHASH}.html" &> /dev/null
				fi
			fi

			# Post to localhost by simply copying files
			if [ "${LOCALHOSTPOST}" == "TRUE" ]; then
				cp "${htmlFile}" "${LOCALHOSTPATH}/${APP}${COMMITHASH}.html"
				# Attempt to make sure the files are readable by all
				chmod a+rw "${LOCALHOSTPATH}/${APP}${COMMITHASH}.html" &> /dev/null
				# Remove logs older then X days
				find "${LOCALHOSTPATH}"* -mtime +"${EXPIRELOGS}" -exec rm {} \;
			fi
		fi
	fi
}

function mailLog() {
	# Only send email if a commit has been made, or there has been an error
	if [ -n "${COMMITHASH}" ] || [ "${message_state}" == "ERROR" ]; then
		if [ "${EMAILHTML}" == "TRUE" ]; then
			# Compile full log information into a single html file
			cat "${deployPath}/html/${EMAILTEMPLATE}/head-email.html" "${trshFile}" > "${htmlEmail}"
			echo "<pre style=\"font: 100% courier,monospace; border: none; overflow: auto; overflow-x: scroll; width: 540px; padding: 0 1em 1em 1em; background: #eee; color: #000;\"><code style=\"font-size: 80%; word-wrap:break-word;\">" >> "${htmlEmail}"
			cat "${logFile}" >> "${htmlEmail}"
			echo "</code></pre>" >> "${htmlEmail}"
			cat "${deployPath}/html/${EMAILTEMPLATE}/foot.html" >> "${htmlEmail}"
			htmlSendmail=$(<"${htmlEmail}")
			# Send the email
			(
			echo "Sender: ${FROM}"
			echo "From: ${FROM} <${FROM}>"
			echo "Reply-To: ${FROM} <${FROM}>"
			echo "To: ${TO}"

			# Is this an error email?
			if [ "${message_state}" == "ERROR" ]; then
				echo "Subject: [ERROR] ${SUBJECT} - ${APP}"
			else
				echo "Subject: [SUCCESS] ${SUBJECT} - ${APP}"
			fi
				
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
			
			# Is this an error email?
			if [ "${message_state}" == "ERROR" ]; then
				echo "Subject: [ERROR] ${SUBJECT} - ${APP}"
			else
				echo "Subject: [SUCCESS] ${SUBJECT} - ${APP}"
			fi
			
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
		# Fire up sendmail
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
