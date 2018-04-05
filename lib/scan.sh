#!/usr/bin/env bash
#
# nikto.sh
#
###############################################################################
# Integrates with nikto to run malware and security scans 
###############################################################################
trace "Loading malware scanning utilities"

# Initialize variables
read -r NIKTO NIKTO_CONFIG scan_html SCAN_RESULT SCAN_MSG SCAN_URL <<< ""
echo "${NIKTO} ${NIKTO_CONFIG} ${scan_html} ${SCAN_RESULT} ${SCAN_MSG}
  ${SCAN_URL}" > /dev/null

function scan_check() {
  if [[ -n "${PRODURL}" ]] || [[ -n "${NIKTO}" ]]; then
    SCAN_URL="${REMOTEURL}/${APP}/scan/"

    SCAN_RESULT=$(echo "${SCAN_MSG//  <td>}")
    if curl -Is "${SCAN_URL}" | grep -q "200"; then
      if curl -s "${SCAN_URL}" | grep -q "0 error"; then
        SCANC="${SUCCESSC}"
        SCAN_MSG="Scan Passed"
      elif curl -s "${SCAN_URL}" | grep -q "error"; then
        SCANC="${DANGERC}"
        SCAN_MSG="Problem Detected"
      fi
      trace "Malware report: ${SCAN_MSG} (see ${SCAN_URL}"
    fi
  fi
}

function scan_host() {
  if [[ -z "${NIKTO}" ]]; then
    warning "Scanning command is not configured, check your setup."; quietExit
  fi

  # Check for nikto
  hash "${NIKTO}" 2>/dev/null || {
    error "Can't find scanning command (${NITKO})" 
  }

  # Create temp files
  scan_html="/tmp/${APP}.scan-$RANDOM.html"; (umask 077 && touch "${scan_html}" &> /dev/null) || log_fail

  # Get headers
  # trace "Header"
  # curl -X HEAD -i "${PRODURL}" &>> "${logFile}"
  
  # Run the scan
  trace "Scanning ${PRODURL}..."
  "${NIKTO}" -config "${NIKTO_CONFIG}" -nointeractive -ask no -Display VE14 -output "${scan_html}" -host "${PRODURL}" > "${scanFile}" &
  spinner $!

  # For testing only
  cp "${scanFile}" ~/verbose_scan.txt

  # Create and clean up the log
  sed -i 's/^.*Running/Running/' "${scanFile}"
  sed -i 's/^.*Loaded/Loaded/' "${scanFile}"
  sed -i '/^V\:/d' "${scanFile}"
  sed -i '/^Running average\: Not enough data/d' "${scanFile}"
  sed -i "s/: currently in plugin 'Nikto Tests'//" "${scanFile}"
  
  # Strip redirects, can get very spammy on a Wordpress project
  sed -i '/Redirects (301) to/d' "${scanFile}"
  cat "${scanFile}" >> "${logFile}"

  # Here's what we need to do to get the HTML ready. Ouch.
  sed -i '/<table/,$!d' "${scan_html}" 
  sed -i '/<p><\/p>/d' "${scan_html}"  
  sed -i '/<div>/d' "${scan_html}"  
  sed -i '/<\/div>/d' "${scan_html}"  
  sed -i 's^class=\"dataTable\"^style=\"width: 100%; max-width: 600px;\"><br /^g' "${scan_html}"  
  sed -i 's^<td class=\"column-head\"^<td valign=\"top\" style=\"width: 25%; font-weight: 700;\"^g' "${scan_html}" 
  sed -i 's^<table class=\"headerTable\"^<br /><table style=\"text-align: left; font-size: 40px;\"^g' "${scan_html}" 
  sed -i -n '/Scan Summary/q;p' "${scan_html}" 
  sed -i '1,5d' "${scan_html}" 
  sed -i '/OSVDB/d' "${scan_html}" 
  sed -i 's^Host Summary^~^g' "${scan_html}"  
  sed -i -e :a -e '$d;N;2,3ba' -e 'P;D' "${scan_html}"

  cat "${deployPath}/html/${HTMLTEMPLATE}/scan/header.html" "${scan_html}" "${deployPath}/html/${HTMLTEMPLATE}/scan/footer.html" > "${htmlFile}"

  SCAN_MSG=$(grep "error" "${htmlFile}")

  # Create scan result text
  SCAN_RESULT=$(echo "${SCAN_MSG//  <td>}")
  SCAN_RESULT=$(echo "${SCAN_RESULT//<\/td>}")
  trace "${SCAN_RESULT}"

  # Set the scan result label text and color
  if [[ "${SCAN_MSG}"  == *"0 errors"* ]]; then
    SCANC="${SUCCESSC}"
    SCAN_MSG="Scan Passed"
  else
    SCANC="${DANGERC}"
    SCAN_MSG="Problem Detected"
  fi

  process_html

  cp "${htmlFile}" "${scan_html}"

  message_state="NOTICE"
  LOGTITLE="Malware Scan"
  notes="Malware scan on ${PRODURL}: ${SCAN_RESULT}"

  safeExit
}
