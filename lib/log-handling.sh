#!/bin/bash
#
# log-handling.sh
#
# Handles parsing and creating logs
trace "Loading log handling"

# Log via email, needs work
function makeLog {
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
					mail -s "$(echo -e "[SUCCESS] ${SUBJECT} - ${APP}\nMIME-Version: 1.0\nContent-Type: text/html")" "${CLIENTEMAIL}" < "${clientEmail}"
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
				chmod a+r "${LOCALHOSTPATH}/${APP}${COMMITHASH}.html" &> /dev/null
				# Remove logs older then X days
				find "${LOCALHOSTPATH}"* -mtime +"${EXPIRELOGS}" -exec rm {} \;
			fi
		fi
	fi
}

function mailLog {
	# Only send email if a commit has been made, or there has been an error
	if [ -n "${COMMITHASH}" ] || [ "${message_state}" == "ERROR" ]; then
		if [ "${EMAILHTML}" == "TRUE" ]; then
			# Compile full log information into a single html file
			cat "${deployPath}/html/${EMAILTEMPLATE}/head-email.html" "${trshFile}" > "${htmlEmail}"
			echo "<pre style=\"font: 100% courier,monospace; border: none; overflow: auto; overflow-x: scroll; width: 540px; padding: 0 1em 1em 1em; background: #eee; color: #000;\"><code style=\"font-size: 80%; word-wrap:break-word;\">" >> "${htmlEmail}"
			cat "${logFile}" >> "${htmlEmail}"
			echo "</code></pre>" >> "${htmlEmail}"
			cat "${deployPath}/html/${EMAILTEMPLATE}/foot.html" >> "${htmlEmail}"
			# Send the email
			# Check for errors - ewwwwwww rewrite this garbage
			if [ "${message_state}" == "ERROR" ]; then
				mail -s "$(echo -e "[ERROR] ${SUBJECT} - ${APP}""\n"MIME-Version: 1.0"\n"Content-Type: text/html)" "${TO}" < "${htmlEmail}"
			else
				mail -s "$(echo -e "[SUCCESS] ${SUBJECT} - ${APP}""\n"MIME-Version: 1.0"\n"Content-Type: text/html)" "${TO}" < "${htmlEmail}"
			fi
		else
			if [ "${message_state}" == "ERROR" ]; then
				mail -s "$(echo -e "[ERROR] ${SUBJECT} - ${APP}""\n"Content-Type: text/plain)" "${TO}" < "${logFile}"
			else
				mail -s "$(echo -e "[SUCCESS] ${SUBJECT} - ${APP}""\n"Content-Type: text/plain)" "${TO}" < "${logFile}"	
			fi
		fi
	fi
}
