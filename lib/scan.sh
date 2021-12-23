#!/usr/bin/env bash
#
# nikto.sh
#
###############################################################################
# Integrates with nikto to run malware and security scans 
###############################################################################

# Initialize variables
var=(NIKTO NIKTO_CONFIG NIKTO_PROXY scan_html SCAN_RESULT SCAN_MSG \
  SCAN_URL)
init_loop

function scan_check() {
  if [[ -n "${PROD_URL}" ]] || [[ -n "${NIKTO}" ]]; then
    SCAN_URL="${REMOTE_URL}/${APP}/scan/"

    SCAN_RESULT=$(echo "${SCAN_MSG//  <td>}")
    # Piping through tac is a workaround to solve a timing issue, see 
    # https://github.com/EMRL/deploy/issues/134
    # For some reason upon migration, tac | tac no longer works
    #if "${curl_cmd}" -LIs --speed-time 900 "${SCAN_URL}" tac | tac | grep -aq "200"; then
    if "${curl_cmd}" -LIs "${SCAN_URL}"  | grep -aq "200"; then
      if "${curl_cmd}" -Ls --speed-time 900 "${SCAN_URL}" | tac | tac | grep -aq "0 error"; then
        SCAN_STATUS="${SUCCESS_COLOR}"; SCAN_BTN="btn-success"
        SCAN_MSG="Scan passed"
      elif "${curl_cmd}" -Ls --speed-time 900 "${SCAN_URL}" | tac | tac | grep -aq "error"; then
        SCAN_STATUS="${DANGER_COLOR}"; SCAN_BTN="btn-danger"
        SCAN_MSG="Problem found"
        trace "error"
      fi
      trace "Malware report: ${SCAN_MSG} (see ${SCAN_URL})"
    fi
  fi
}

function scan_host() {
  if [[ -z "${NIKTO}" ]]; then
    warning "Scanning command is not configured, check your setup."; quiet_exit
  fi

  # Check for nikto
  hash "${NIKTO}" 2>/dev/null || {
    error "Can't find scanning command (${NITKO})" 
  }

  # Only scan production URL
  if [[ -z "${PROD_URL}" ]]; then
    warning "Production server is not defined, check your setup."; quiet_exit
  fi

  # Create temp files
  scan_html="/tmp/${APP}.scan-$RANDOM.html"; (umask 077 && touch "${scan_html}" &> /dev/null) || log_fail
  
  # Run the scan
  trace "Scanning ${PROD_URL}..."
  # Spinners commented out for now, causing issues when running from a crontab
  if [[ -z "${NIKTO_PROXY}" ]]; then
    "${NIKTO}" -config "${NIKTO_CONFIG}" -nointeractive -ask no -Display VE14 -Tuning 013789c -no404 -output "${scan_html}" -host "${PROD_URL}" > "${scan_file}" #&
    #spinner $!
  else
    "${NIKTO}" -config "${NIKTO_CONFIG}" -nointeractive -ask no -Display VE14 -no404 -output "${scan_html}" -useproxy "${NIKTO_PROXY}" -host "${PROD_URL}" > "${scan_file}" #&
    #spinner $!
  fi

  # For testing only
  cp "${scan_file}" ~/verbose_scan.txt

  # Create and clean up the log
  sed -i -e 's/^.*Running/Running/' "${scan_file}" \
    -e 's/^.*Loaded/Loaded/' \
    -e '/^V\:/d' \
    -e '/^Running average\: Not enough data/d' \
    -e "s/: currently in plugin 'Nikto Tests'//" \
    "${scan_file}"
  
  # Strip redirects, can get very spammy on a Wordpress project
  sed -i '/Redirects (301) to/d' "${scan_file}"
  cat "${scan_file}" >> "${log_file}"

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
  sed -i 's^Host Summary^<hr style=\"width: 600px;\">^g' "${scan_html}"  
  sed -i -e :a -e '$d;N;2,3ba' -e 'P;D' "${scan_html}"

  # Create the scan report in the new dashboard format, this is kinda
  # maybe temporary, it's getting pretty tangled
  assign_nav
  project_scan

  cat "${stir_path}/html/${HTML_TEMPLATE}/scan/header.html" "${scan_html}" "${stir_path}/html/${HTML_TEMPLATE}/scan/footer.html" > "${html_file}"

  SCAN_MSG=$(grep -a "error" "${html_file}")

  # Create scan result text
  SCAN_RESULT=$(echo "${SCAN_MSG//  <td>}")
  SCAN_RESULT=$(echo "${SCAN_RESULT//<\/td>}")
  trace "${SCAN_RESULT}"

  # Set the scan result label text and color
  if [[ "${SCAN_MSG}"  == *"0 errors"* ]]; then
    SCAN_STATUS="${SUCCESS_COLOR}"
    SCAN_MSG="Scan passed"
    message_state="PASSED"
  else
    SCAN_STATUS="${DANGER_COLOR}"
    SCAN_MSG="Problem found"
    message_state="ERROR"
  fi

  process_html

  cp "${html_file}" "${scan_html}"
  
  LOGTITLE="Malware Scan"
  notes="Malware scan on ${PROD_URL}: ${SCAN_RESULT}"

  clean_exit
}
