#!/usr/bin/env bash
#
# report.sh
#
###############################################################################
# Handles parsing and creating monthly work reports
###############################################################################
trace "Loading report handling"

# Initialize variables
read -r CURMTH CURYR PRVMTH PRVYR LASTDY <<< ""
echo "${CURMTH} ${CURYR} ${PRVMTH} ${PRVYR} ${LASTDY}" > /dev/null

function create_report() {

  # Make sure we've got cal, or don't bother
  hash cal 2>/dev/null || {
    console "Creating reports requires the cal utility whichh cannot be found."; quietExit
  }

  message_state="REPORT"
  htmlDir

  # Get the first and last day of last month
  CURMTH="$(date +%m)"
  CURYR="$(date +%Y)"

  if [[ "${CURMTH}" -eq 1 ]]; then
    PRVMTH="11"
    PRVYR=`expr "${CURYR}" - 1`
  elif [[ "${CURMTH}" -eq 2 ]]; then
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
    # If INCLUDEHOSTING is equal to something other than TRUE (And not FALSE), 
    # its value will be used as the text string in the report 
    if [[ "${INCLUDEHOSTING}" == "TRUE" ]]; then
      INCLUDEHOSTING="Web hosting for the month of ${LAST_MONTH}"
    fi
    echo "<tr class=\"item-row\"><td class=\"item-name\"><div class=\"delete-wpr\">${TASK}<a class=\"delete\" href=\"javascript:;\" title=\"Remove row\">X</a></div></td><td class=\"description\"><div contenteditable class=\"editable\">${INCLUDEHOSTING}</div></td></tr>" >> "${statFile}"
  fi

  trace "git log --all --no-merges --first-parent --before=\"${CURYR}-${CURMTH}-1 00:00\" --after=\"${PRVYR}-${PRVMTH}-${LASTDY} 00:00\" --pretty=format:\"<tr class=\"item-row\"><td class=\"item-name\"><div class=\"delete-wpr\">%h<a class=\"delete\" href=\"javascript:;\" title=\"Remove row\">X</a></div></td><td class=\"description\"><div contenteditable class=\"editable\">%s</div></td></tr>\""
  git log --all --no-merges --first-parent --before="${CURYR}-${CURMTH}-1 00:00" --after="${PRVYR}-${PRVMTH}-${LASTDY} 00:00" --pretty=format:"<tr class=\"item-row\"><td class=\"item-name\"><div class=\"delete-wpr\">%h<a class=\"delete\" href=\"javascript:;\" title=\"Remove row\">X</a></div></td><td class=\"description\"><div contenteditable class=\"editable\">%s</div></td></tr>" >> "${statFile}"

  # If it's an empty report, this empty row will keep the javascript from breaking. Kludgy I know.
  if [[ ! -s "${statFile}" ]]; then
    echo "<tr class=\"item-row\" id=\"hiderow\" style=\"display: none;\"><td></td><td></td></tr>" > "${statFile}"
  fi

  # Compile full report 
  cat "${deployPath}/html/${HTMLTEMPLATE}/report/header.html" "${statFile}" "${deployPath}/html/${HTMLTEMPLATE}/report/footer.html" > "${htmlFile}"

  # Filter and replace template variables
  process_html
}
