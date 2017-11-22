#!/bin/bash
#
# report.sh
#
###############################################################################
# Handles parsing and creating monthly work reports
###############################################################################
trace "Loading report handling"

function createReport() {
	message_state="REPORT"
	htmlDir

	# Get the first and last day of last month
	CURMTH="$(date +%m)"
	CURYR="$(date +%Y)"

	if [[ "${CURMTH}" -eq 1 ]]; then
		PRVMTH="12"
		PRVYR=`expr "${CURYR}" - 1`
	else PRVMTH=`expr "${CURMTH}" - 2`
		PRVYR="${CURYR}"
	fi

	if [[ "${PRVMTH}" -lt 10 ]];
		then PRVMTH="0${PRVMTH}"
	fi

	# Try to setup the month/day count
	LASTDY=`cal ${PRVMTH} ${PRVYR} | egrep "28|29|30|31" |tail -1 |awk '{print $NF}'`

	if [[ -n "${INCLUDEHOSTING}" ]] && [[ "${INCLUDEHOSTING}" != "FALSE" ]]; then
		if [[ "${INCLUDEHOSTING}" == "TRUE" ]]; then
			INCLUDEHOSTING="Monthly web hosting"
		fi
		echo "<tr class=\"item-row\"><td class=\"item-name\"><div class=\"delete-wpr\">${TASK}<a class=\"delete\" href=\"javascript:;\" title=\"Remove row\">X</a></div></td><td class=\"description\">Web hosting for the month of ${LASTMONTH}</td></tr>" >> "${statFile}"
	fi

	#if [[ $(git log --before={'date "+%Y-%m-01"'} --after=${PRVYR}-${PRVMTH}-31) ]]; then
	git log --all --no-merges --first-parent --before={'date "+%Y-%m-01"'} --after="${PRVYR}-${PRVMTH}-31 00:00" --pretty=format:"<tr class=\"item-row\"><td class=\"item-name\"><div class=\"delete-wpr\">%h<a class=\"delete\" href=\"javascript:;\" title=\"Remove row\">X</a></div></td><td class=\"description\">%s</td></tr>" >> "${statFile}"

	# If it's an empty report, this empty row will keep the javascript from breaking. Kludgy I know.
	if [[ ! -s "${statFile}" ]]; then
		echo "<tr class=\"item-row\" id=\"hiderow\" style=\"display: none;\"><td></td><td></td></tr>" > "${statFile}"
	fi

	# Compile full report 
	cat "${deployPath}/html/${HTMLTEMPLATE}/report/header.html" "${statFile}" "${deployPath}/html/${HTMLTEMPLATE}/report/footer.html" > "${htmlFile}"

	# Filter and replace template variables
	processHTML
}
