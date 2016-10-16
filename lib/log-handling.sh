#!/bin/bash
#
# log-handling.sh
#
# Handles parsing and creating logs
trace "Loading log-handling.sh"

# Log via email, needs work
function mailLog {
	# Filter as needed
	if [ "${NOPHP}" == "TRUE" ]; then
		grep -vE "(PHP |Notice:|Warning:|Strict Standards:)" "${logFile}" > "${postFile}"
		cat "${postFile}" > "${logFile}"
	fi

	if [ "${EMAILHTML}" == "TRUE" ]; then
		if [ "${message_state}" == "ERROR" ]; then
			if [ -z "${error_msg}" ]; then
				error_msg="Something went wrong."
			fi
			# I really hate all this repeating inline code, I'll come back to this and make it better
			if [ -z "${PRODURL}" ]; then
				echo "<strong>Date:</strong> ${NOW}<br /><strong>Project:</strong> ${PROJNAME} (${PROJCLIENT})</p><p style=\"font-family: Arial, sans-serif; font-style: normal; font-weight: 400; color: #000;\"><strong style=\"color: #C70039;\">ERROR: ${error_msg}</strong></p><pre style=\"font: 100% courier,monospace; border: 1px solid #ccc; overflow: auto; overflow-x: scroll; width: 540px; padding: 0 1em 1em 1em; background: #eee; color: #000;\"><code style=\"font-size: 80%;\">" > "${postFile}"
			else
				echo "<strong>Date:</strong> ${NOW}<br /><strong>Project:</strong> ${PROJNAME} (${PROJCLIENT})<br /><strong>URL:</strong> <a style=\"display: inline-block; max-width: 100%; color: #fff; background-color: #000; text-decoration: none;\" href=\"${PRODURL}\">${PRODURL}</a></p><p style=\"font-family: Arial, sans-serif; font-style: normal; font-weight: 400; color: #000;\"><strong style=\"color: #C70039;\">ERROR: ${error_msg}</strong></p><pre style=\"font: 100% courier,monospace; border: 1px solid #ccc; overflow: auto; overflow-x: scroll; width: 540px; padding: 0 1em 1em 1em; background: #eee; color: #000;\"><code style=\"font-size: 80%;\">" > "${postFile}"
			fi
		else
			if [ -z "${PRODURL}" ]; then
				echo "<strong>Date:</strong> ${NOW}<br /><strong>Project:</strong> ${PROJNAME} (${PROJCLIENT})</p><p style=\"font-family: Arial, sans-serif; font-style: normal; font-weight: 400; color: #000;\"><strong>Commit <a style=\"display: inline-block; max-width: 100%; color: #fff; background-color: #159818; text-decoration: none;\" href=\"${COMMITURL}\">${COMMITHASH}</a>:</strong> ${notes}</p><pre style=\"font: 100% courier,monospace; border: 1px solid #ccc; overflow: auto; overflow-x: scroll; width: 540px; padding: 0 1em 1em 1em; background: #eee; color: #000;\"><code style=\"font-size: 80%;\">" > "${postFile}"
			else
				echo "<strong>Date:</strong> ${NOW}<br /><strong>Project:</strong> ${PROJNAME} (${PROJCLIENT})<br /><strong>URL:</strong> <a style=\"display: inline-block; max-width: 100%; color: #fff; background-color: #000; text-decoration: none;\" href=\"${PRODURL}\">${PRODURL}</a></p><p style=\"font-family: Arial, sans-serif; font-style: normal; font-weight: 400; color: #000;\"><strong>Commit <a style=\"display: inline-block; max-width: 100%; color: #fff; background-color: #159818; text-decoration: none;\" href=\"${COMMITURL}\">${COMMITHASH}</a>:</strong> ${notes}</p><pre style=\"font: 100% courier,monospace; border: 1px solid #ccc; overflow: auto; overflow-x: scroll; width: 540px; padding: 0 1em 1em 1em; background: #eee; color: #000;\"><code style=\"font-size: 80%;\">" > "${postFile}"
			fi
		fi
		cat "${deployPath}/html/emrl/head.html" "${postFile}" "${logFile}" "${deployPath}/html/emrl/foot.html" > "${htmlFile}"
		cp "${htmlFile}" ~/debug.html
		mail -s "$(echo -e "${SUBJECT} - ${APP}""\n"MIME-Version: 1.0"\n"Content-Type: text/html)" "${TO}" < "${htmlFile}"
	else
		mail -s "$(echo -e "${SUBJECT} - ${APP}""\n"Content-Type: text/plain)" "${TO}" < "${logFile}"
	fi
}
