#!/bin/bash
#
# log-handling.sh
#
# Handles parsing and creating logs
trace "Loading log handling"

function makeLog() {
	# Clean up stuff that is most likely there
	sed -i "/git reset HEAD/d" "${logFile}"
	sed -i "/Checking out files:/d" "${logFile}"
	sed -i "/Unpacking objects:/d" "${logFile}"

	# Clean up stuff that has a small chance of being there
	sed -i "/--:--:--/d" "${logFile}"
	sed -i "/% Received/d" "${logFile}"
	sed -i "/\Dload/d" "${logFile}"
	sed -i "/\[34m/d" "${logFile}"
	sed -i "/\[31m/d" "${logFile}"
	sed -i "/\[32m/d" "${logFile}"
	sed -i "/\[96m/d" "${logFile}"
	sed -i "/no changes added to commit/d" "${logFile}"
	sed -i "/to update what/d" "${logFile}"
	sed -i "/to discard changes/d" "${logFile}"
	sed -i "/Changes not staged for/d" "${logFile}"

	# Clean up mina's goobers
	if [[ "${DEPLOY}" == *"mina"* ]]; then
		sed -i "/0m Creating a temporary build path/c\Creating a temporary build path" "${logFile}"
		sed	-i "/0m Fetching new git commits/c\Fetching new git commits" "${logFile}"
		sed	-i "/0m Using git branch '${PRODUCTION}'/c\Using git branch '${PRODUCTION}'" "${logFile}"
		sed -i "/0m Using this git commit/c\Using this git commit" "${logFile}"
		sed -i "/0m Cleaning up old releases/c\Cleaning up old releases" "${logFile}"
		sed -i "/0m Build finished/c\Build finished" "${logFile}"

		# Totally remove these lines
		sed -i "/----->/d" "${logFile}"
		sed -i "/0m/d" "${logFile}"
		sed -i "/Resolving deltas:/d" "${logFile}"
		sed -i "/remote:/d" "${logFile}"
		sed -i "/Receiving objects:/d" "${logFile}"
		sed -i "/Resolving deltas:/d" "${logFile}"
	fi

	# Filter raw log output as configured by user
	if [[ "${NOPHP}" == "TRUE" ]]; then
		grep -vE "(PHP |Notice:|Warning:|Strict Standards:)" "${logFile}" > "${postFile}"
		cat "${postFile}" > "${logFile}"
	fi

	# Is this a publish only?
	if [[ "${PUBLISH}" == "1" ]] && [[ -z "${notes}" ]]; then	
		notes="Published to production and marked as deployed"
	fi

	# Setup a couple of variables
	VIEWPORT="680"
	VIEWPORTPRE=$(expr ${VIEWPORT} - 80)

	# IF we're using HTML emails, let's get to work
	if [[ "${EMAILHTML}" == "TRUE" ]]; then
		htmlBuild
		cat "${htmlFile}" > "${trshFile}"

		# If this is an approval email, strip out PHP
		if [[ "${message_state}" == "APPROVAL NEEDED" ]]; then 
			sed -i '/<?php/,/?>/d' "${trshFile}"
			sed -e "s^EMAIL BUTTONS: BEGIN^EMAIL BUTTONS: BEGIN //-->^g" -i "${trshFile}"
		fi

		# Load the email into a variable
		htmlSendmail=$(<"${trshFile}")
	fi



	# Create HTML/PHP logs for viewing online
	if [[ "${REMOTELOG}" == "TRUE" ]]; then
		htmlDir
		# For web logs, VIEWPORT should be 960
		VIEWPORT="960"
		VIEWPORTPRE=$(expr ${VIEWPORT} - 80)
		# Build the html email and details pages
		htmlBuild
		# Build the commit history page
		# gitHistory
		# Strip out the buttons that self-link
		sed -e "s^// BUTTON: BEGIN //-->^BUTTON HIDE^g" -i "${htmlFile}"
		postLog
	fi
}

function htmlBuild() {
	# Build out the HTML
	LOGSUFFIX="html"
	if [ "${message_state}" == "ERROR" ]; then
		# Oh man, this is an error
		notes="${error_msg}"
		LOGTITLE="Deployment Error"
		# Create the header
		cat "${deployPath}/html/${EMAILTEMPLATE}/header.html" "${deployPath}/html/${EMAILTEMPLATE}/error.html" > "${htmlFile}"
	else
		# Does this project need to be approved before finalizing deployment?
		#if [[ "${REQUIREAPPROVAL}" == "TRUE" ]] && [[ "${APPROVE}" != "1" ]] && [[ "${DIGEST}" != "1" ]] && [[ -f "${WORKPATH}/${APP}/.queued" ]]; then
		if [[ "${REQUIREAPPROVAL}" == "TRUE" ]] && [[ "${APPROVE}" != "1" ]] && [[ "${DIGEST}" != "1" ]]; then
			message_state="APPROVAL NEEDED"
			LOGTITLE="Approval Needed"
			LOGSUFFIX="php"
			# cat "${deployPath}/html/${EMAILTEMPLATE}/header.html" "${deployPath}/html/${EMAILTEMPLATE}/approve.html" > "${htmlFile}"
			cat "${deployPath}/html/${EMAILTEMPLATE}/approval.php" > "${htmlFile}"
		else
			if [[ "${AUTOMATE}" == "1" ]] && [[ "${APPROVE}" != "1" ]] && [[ "${UPD1}" == "1" ]] && [[ "${UPD2}" == "1" ]]; then
				message_state="NOTICE"
				LOGTITLE="Scheduled Deployment"
				notes="No updates available for deployment"
			else
				# Looks like we've got a normal successful deployment
				message_state="SUCCESS"
				# Is this a scheduled updated?
				if [[ "${AUTOMATE}" == "1" ]]; then
					LOGTITLE="Scheduled Deployment"
				else
					LOGTITLE="Deployment Log"
				fi
			fi
			cat "${deployPath}/html/${EMAILTEMPLATE}/header.html" "${deployPath}/html/${EMAILTEMPLATE}/success.html" > "${htmlFile}"
		fi
	fi

	# Create URL
	if [[ "${PUBLISH}" == "1" ]]; then
		LOGURL="${REMOTEURL}/${APP}/${EPOCH}.${LOGSUFFIX}"
		REMOTEFILE="${EPOCH}.${LOGSUFFIX}"
	else
		if [[ "${message_state}" != "SUCCESS" ]] || [[ -z "${COMMITHASH}" ]]; then
			LOGURL="${REMOTEURL}/${APP}/${message_state}-${EPOCH}.${LOGSUFFIX}"
			REMOTEFILE="${message_state}-${EPOCH}.${LOGSUFFIX}"
		else
			LOGURL="${REMOTEURL}/${APP}/${COMMITHASH}.${LOGSUFFIX}"
			REMOTEFILE="${COMMITHASH}.${LOGSUFFIX}"
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
		-e "s^{{REMOTEURL}}^${REMOTEURL}^g" \
		-e "s^{{VIEWPORTPRE}}^${VIEWPORTPRE}^g" \
		-e "s^{{PATHTOREPO}}^${WORKPATH}/${APP}^g" \
		"${trshFile}" > "${htmlFile}"

	# Clean up header stuff that we don't need
	if [[ -z "${DEVURL}" ]]; then
		sed -i '/<strong>Staging URL:/d' "${htmlFile}"
	fi

	if [[ -z "${PRODURL}" ]]; then
		sed -i '/<strong>Production URL:/d' "${htmlFile}"
	fi

	if [[ -z "${PROJCLIENT}" ]]; then
		sed -i 's/()//' "${htmlFile}"
	fi  

	if [[ -z "${CLIENTLOGO}" ]]; then
		sed -i '/CLIENTLOGO/d' "${htmlFile}"
	fi          
}

# Git history function
function gitHistory() {
	htmlDir	
	# Collect gravatars for all the authors in this repo
	for AUTHOR in $(git log --pretty=format:"%ae|%an" | sort | uniq); do
		AUTHOREMAIL=$(echo $AUTHOR | cut -d\| -f1 | tr -d '[[:space:]]' | tr '[:upper:]' '[:lower:]')
		AUTHORNAME=$(echo $AUTHOR | cut -d\| -f2)
		GRAVATAR="http://www.gravatar.com/avatar/$(echo -n $AUTHOREMAIL | md5sum)?d=404&s=200"
		IMGFILE="${LOCALHOSTPATH}/${APP}/avatar/$AUTHORNAME.png"
		# if [[ ! -f $IMGFILE ]]; then # If you wanna cache?
	    curl -fso "${IMGFILE}" "${GRAVATAR}"
		# fi
	done

	# Attempt to get analytics
	analytics

	# Assemble the file
	DIGESTWRAP="$(<${deployPath}/html/${EMAILTEMPLATE}/digest/wrap.html)"

	# If there have been no commits in the last week, skip creating the digest
	if [[ $(git log --since="7 days ago") ]]; then
		git log --pretty=format:"%n$DIGESTWRAP<strong>%ncommit <a style=\"color: #47ACDF; text-decoration: none; font-weight: bold;\" href=\"${REMOTEURL}/${APP}/%h.html\">%h</a>%nAuthor: %aN%nDate: %aD (%cr)%n%s</td></tr></table>" --since="7 days ago" > "${statFile}"
		sed -i '/^commit/ s/$/ <\/strong><br>/' "${statFile}"
		sed -i '/^Author:/ s/$/ <br>/' "${statFile}"
		sed -i '/^Date:/ s/$/ <br><br>/' "${statFile}"
		cat "${deployPath}/html/${EMAILTEMPLATE}/digest/header.html" "${statFile}" "${deployPath}/html/${EMAILTEMPLATE}/digest/footer.html" > "${trshFile}"

		# Randomize a positive Monday thought
		array[0]="Hope you had a good weekend!"
		array[1]="Alright Monday, let's do this."
		array[2]="Oh, hello Monday."
		array[3]="Welcome back, how was your weekend?"
		array[4]="Happy Monday and welcome back!"
		array[5]="Hello and good morning!"
		SIZE="${#array[@]}"
		RND="$(($RANDOM % $SIZE))"
		GREETING="${array[$RND]}"

		# Process and replace variables
		sed -e "s^{{WEEKOF}}^${WEEKOF}^g" \
		 	-e "s^{{NOW}}^${NOW}^g" \
			-e "s^{{PROJCLIENT}}^${PROJCLIENT}^g" \
			-e "s^{{GRAVATARURL}}^${REMOTEURL}\/${APP}\/avatar^g" \
			-e "s^{{DIGESTWRAP}}^${DIGESTWRAP}^g" \
			-e "s^{{PROJCLIENT}}^${PROJCLIENT}^g" \
			-e "s^{{CLIENTLOGO}}^${CLIENTLOGO}^g" \
			-e "s^{{PRODURL}}^${PRODURL}^g" \
			-e "s^{{GREETING}}^${GREETING}^g" \
			-e "s^{{REMOTEURL}}^${REMOTEURL}^g" \
			-e "s^{{ANALYTICSMSG}}^${ANALYTICSMSG}^g" \
			-e "s^{{STATURL}}^${REMOTEURL}\/${APP}\/stats^g" \
			"${trshFile}" > "${statFile}"

		if [[ -z "${RESULT}" ]] || [[ "${RESULT}" == "0" ]] || [[ "${SIZE}" == "0" ]]; then
			sed -i '/ANALYTICS/d' "${statFile}"
		fi   

		if [[ -z "${CLIENTLOGO}" ]]; then
			sed -i '/CLIENTLOGO/d' "${statFile}"
		fi   

		# Get the email payload ready
		digestSendmail=$(<"${statFile}")
	else
		echo "No activity found, canceling digest."
		safeExit
	fi
}

# Remote log function 
function postLog() {
	if [[ "${REMOTELOG}" == "TRUE" ]]; then
		# Post to localhost by simply copying files
		if [[ "${LOCALHOSTPOST}" == "TRUE" ]] && [[ -f "${htmlFile}" ]]; then
			# Check that directory exists
			htmlDir

			# Is there a commit hash?	
			if [[ -n "${REMOTEFILE}" ]]; then
				cp "${htmlFile}" "${LOCALHOSTPATH}/${APP}/${REMOTEFILE}"
				chmod a+rw "${LOCALHOSTPATH}/${APP}/${REMOTEFILE}" &> /dev/null
			fi

			# Post the digest
			if [[ "${DIGEST}" == "1" ]]; then
				REMOTEFILE="digest-${EPOCH}.html"
				cp "${statFile}" "${LOCALHOSTPATH}/${APP}/${REMOTEFILE}"
				chmod a+rw "${LOCALHOSTPATH}/${APP}/${REMOTEFILE}" &> /dev/null
			fi
	
			# Remove logs older then X days
			if [[ -n "${EXPIRELOGS}" ]]; then
				find "${LOCALHOSTPATH}/${APP}"* -mtime +"${EXPIRELOGS}" -exec rm {} \;
			fi
		fi

		# Send the files through SCP (not yet enabled)
		if [[ "SCPPOST" == "TRUE" ]]; then
			if [[ -n "${SCPPASS}" ]]; then
				sshpass -p "${SCPPASS}" scp -o StrictHostKeyChecking=no "${htmlFile}" "${SCPUSER}"@"${SCPHOST}":"${SCPHOSTPATH}/${APP}${COMMITHASH}.html" &> /dev/null
			else
				scp "${htmlFile}" "${SCPUSER}"@"${SCPHOST}":"${SCPHOSTPATH}/${APP}/{COMMITHASH}.html" &> /dev/null
			fi
		fi
	fi
}

function mailLog() {
	# Only send email if a commit has been made, an approval is required, or there has been an error
	if [[ -n "${COMMITHASH}" ]] || [[ "${message_state}" == "ERROR" ]] || [[ "${message_state}" == "APPROVAL NEEDED" ]] || [[ "${AUTOMATE}" == "1" ]]; then
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

	# Is this a digest email?
	if [[ "${NOTIFYCLIENT}" == "TRUE" ]] && [[ -n "${CLIENTEMAIL}" ]] && [[ "${DIGEST}" == "1" ]] && [[ -n "${digestSendmail}" ]]; then
		# Tweak the WEEKOF for the subject line
		WEEKOF="$(date -d '7 days ago' +"%B %d, %Y")"
		# Send the email
		(
		echo "Sender: ${FROM}"
		echo "From: EMRL <${FROM}>"
		echo "Reply-To: ${FROM} <${FROM}>"
		echo "To: ${CLIENTEMAIL}"
		echo "Subject: ${PROJNAME} updates for the week of ${WEEKOF}"				
		echo "Content-Type: text/html"
		echo
		echo "${digestSendmail}";
		) | "${MAILPATH}"/sendmail -t
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

function htmlDir() {
	if [[ ! -d "${LOCALHOSTPATH}/${APP}" ]]; then
		mkdir "${LOCALHOSTPATH}/${APP}"
	fi

	if [[ ! -d "${LOCALHOSTPATH}/${APP}/avatar" ]]; then
		mkdir "${LOCALHOSTPATH}/${APP}/avatar"
	fi
}
