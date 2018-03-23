#!/usr/bin/env bash
#
# nikto.sh
#
###############################################################################
# Integrates with nikto to run malware and security scans 
###############################################################################

# Initialize variables
read -r NIKTO NIKTO_CONFIG <<< ""
echo "${NIKTO} ${NIKTO_CONFIG}" > /dev/null

function scan_host() {
  if [[ -z "${NIKTO}" ]]; then
    return
  fi

  # Check for nikto
  hash "${NIKTO}" 2>/dev/null || {
    error "Can't find scanning command (${NITKO})" 
  }

  # Get headers
  # trace "Header"
  # curl -X HEAD -i "${PRODURL}" &>> "${logFile}"
  
  # Run the scan
  trace "Scanning ${PRODURL}..."
  "${NIKTO}" -config "${NIKTO_CONFIG}" -nointeractive -ask no -Display VP14 -Tuning x12b -host "${PRODURL}" >> "${logFile}" &
  spinner $!
  message_state="NOTICE"
  LOGTITLE="Malware Scan"
  notes="Malware scan on ${PRODURL}"

  # Clean up the log
  sed -i 's/^.*Running/Running/' "${logFile}"
  sed -i 's/^.*Loaded/Loaded/' "${logFile}"
  sed -i '/^V\:/d' "${logFile}"
  sed -i '/^Running average\: Not enough data/d' "${logFile}"
  sed -i "s/: currently in plugin 'Nikto Tests'//" "${logFile}"
  
  # Strip redirects, can get very spammy on a Wordpress project
  sed -i '/Redirects (301) to/d' "${logFile}"
  safeExit
}
