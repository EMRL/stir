#!/usr/bin/env bash
#
# nikto.sh
#
###############################################################################
# Integrates with nikto to run malware and security scans 
###############################################################################
trace "Loading malware scanning utilities"

# Initialize variables
read -r NIKTO NIKTO_CONFIG NIKTO_PROXY scan_html SCAN_RESULT SCAN_MSG \
  SCAN_URL <<< ""
echo "${NIKTO} ${NIKTO_CONFIG} ${scan_html} ${SCAN_RESULT} ${SCAN_MSG}
  ${SCAN_URL}" > /dev/null

function scan_check() {
  if [[ -n "${PRODURL}" ]] || [[ -n "${NIKTO}" ]]; then
    SCAN_URL="${REMOTEURL}/${APP}/scan/"

    SCAN_RESULT=$(echo "${SCAN_MSG//  <td>}")
    # Piping through tac is a workaround to solve a timing issue, see 
    # https://github.com/EMRL/deploy/issues/134
    #if curl -LIs --speed-time 900 "${SCAN_URL}" tac | tac | grep -q "200"; then
    if curl -LIs "${SCAN_URL}"  | grep -q "200"; then
      if curl -Ls --speed-time 900 "${SCAN_URL}" tac | tac | grep -q "0 error"; then
        SCANC="${SUCCESSC}"; SCAN_BTN="btn-success"
        SCAN_MSG="Scan passed"
      elif curl -Ls --speed-time 900 "${SCAN_URL}" tac | tac | grep -q "error"; then
        SCANC="${DANGERC}"; SCAN_BTN="btn-danger"
        SCAN_MSG="Problem found"
      fi
      trace "Malware report: ${SCAN_MSG} (see ${SCAN_URL})"
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
  
  # Run the scan
  trace "Scanning ${PRODURL}..."
  if [[ -z "${NIKTO_PROXY}" ]]; then
    "${NIKTO}" -config "${NIKTO_CONFIG}" -nointeractive -ask no -Display VE14 -Tuning 013789c -no404 -output "${scan_html}" -host "${PRODURL}" > "${scanFile}" &
    spinner $!
  else
    "${NIKTO}" -config "${NIKTO_CONFIG}" -nointeractive -ask no -Display VE14 -no404 -output "${scan_html}" -useproxy "${NIKTO_PROXY}" -host "${PRODURL}" > "${scanFile}" &
    spinner $!
  fi

  # For testing only
  cp "${scanFile}" ~/verbose_scan.txt

  # Create and clean up the log
  sed -i -e 's/^.*Running/Running/' "${scanFile}" \
    -e 's/^.*Loaded/Loaded/' \
    -e '/^V\:/d' \
    -e '/^Running average\: Not enough data/d' \
    -e "s/: currently in plugin 'Nikto Tests'//" \
    "${scanFile}"
  
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
  sed -i 's^<table class=\"headerTable\"^<br /><table style=\"text-align: left; font-size: 40px; overflow-wrap: break-word; word-wrap: break-word; -ms-word-break: break-all; word-break: break-word;\"^g' "${scan_html}" 
  sed -i -n '/Scan Summary/q;p' "${scan_html}" 
  sed -i '1,5d' "${scan_html}" 
  sed -i '/OSVDB/d' "${scan_html}" 
  sed -i 's^<a href^<a style=\"color: {{PRIMARY}}\" href^g' "${scan_html}" 
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
    SCAN_MSG="Scan passed"
    message_state="PASSED"
  else
    SCANC="${DANGERC}"
    SCAN_MSG="Problem found"
    message_state="ERROR"
  fi

  process_html

  cp "${htmlFile}" "${scan_html}"
  
  LOGTITLE="Malware Scan"
  notes="Malware scan on ${PRODURL}: ${SCAN_RESULT}"

  safeExit
}
