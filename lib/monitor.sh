#!/usr/bin/env bash
#
# monitor.sh
#
###############################################################################
# Uses PHP Server Monitor and an add-on API to retrieve a production server's 
# uptime and latency
###############################################################################

function server_monitor() {
  # Don't bother unless all the needed variables are declared
  if [[ -n "${MONITORURL}" ]] && [[ -n "${MONITORUSER}" ]] && [[ -n "${SERVERID}" ]] && [[ -n "${MONITORPASS}" ]]; then
    # What kind of log is this?
    if [[ "${REPORT}" == "1" ]]; then
      # Last 30 days; this will not correlate exactly with the time range of the report 
      # which is dealing with the last calendar month, but oh well we get what we pay
      # for. The PHP Monitor API has no ability to look up results in that way 
      MONITORHOURS="720"
    elif [[ "${DIGEST}" == "1" ]] || [[ "${PROJSTATS}" == "1" ]] || [[ "${SCAN}" == "1" ]]; then
      # Digests and stats should average 7 days
      MONITORHOURS="168"
    else
      # Anything else defaults to 24 hours
      MONITORHOURS="24"
    fi
    server_monitor_log
    trace "Uptime: ${UPTIME}% / Latency: ${LATENCY} (avg. over last ${MONITORHOURS} hours)"
  fi
}

function server_monitor_test() {
  notice "Testing server monitor integration..."
  if [[ -n "${MONITORURL}" ]] && [[ -n "${MONITORUSER}" ]] && [[ -n "${SERVERID}" ]] && [[ -n "${MONITORPASS}" ]]; then
    console "Monitor URL: ${MONITORURL}"
    console "User: ${MONITORUSER}"
    console "Server ID: ${SERVERID}"
    console "Password file: ${MONITORPASS}"
  else
    warning "Server monitoring is not configured; check your project's configuration file."
    return
  fi

  # Check last 7 days for the sake of the test
  MONITORHOURS="24"
  server_monitor_log
  console "API: ${MONITORAPI}"  
  notice "Results (last 24 hours)"
  console "Uptime: ${UPTIME}%"
  console "Latency: ${LATENCY}s"
}

function server_monitor_log() {
  # Load the password and setup the curl command
  MONITORPASS=$(<$MONITORPASS)
  MONITORAPI="${MONITORURL}?tag=serveruptime&email=${MONITORUSER}&app_password=${MONITORPASS}&server_id=${SERVERID}&HoursUnit=${MONITORHOURS}"
  curl -s --request GET "${MONITORAPI}" -o "${trshFile}"
  # Uptime
  UPTIME=$(grep -Po '"uptime":.*?[^\\]",' ${trshFile})
  UPTIME="$(cut -d ',' -f 1 <<< "${UPTIME}")"
  # Isolate the value we need
  UPTIME="$(sed 's/^[^:]*://g' <<< "${UPTIME}")"
  # Round to two decimal places
  UPTIME="$(printf '%0.2f\n' "${UPTIME}")"
  # Lop off the .00 if we're at 100%
  if [[ "${UPTIME}" == "100.00" ]]; then
    UPTIME="100"
  fi

  # Latency
  LATENCY="$(grep -Po '"average_latency":.*?[^\\]",' ${trshFile})"
  LATENCY="$(cut -d ',' -f 1 <<< "${LATENCY}")"
  # Isolate the value we need
  LATENCY="$(sed 's/^[^:]*://g' <<< "${LATENCY}")"
  # Round to two decimal places
  LATENCY="$(printf '%0.2f\n' "${LATENCY}")"

  # Set colors for html reports
  if [[ "${UPTIME}" == "100" ]]; then
    UPTIMEC="${SUCCESSC}"; UPTIME_BTN="btn-success"
  elif [[ "${UPTIME}" > "97" || "${UPTIME}" == "97" ]]; then
    UPTIMEC="${SUCCESSC}"; UPTIME_BTN="btn-success"
  elif [[ "${UPTIME}" > "88" && "${UPTIME}" < "97" ]]; then
    UPTIMEC="${WARNINGC}"; UPTIME_BTN="btn-warning"
  else
    UPTIMEC="${DANGERC}"; UPTIME_BTN="btn-danger"
  fi

  if [[ "${LATENCY}" < "2.2" || "${LATENCY}" == "2.2" ]]; then
    LATENCYC="${SUCCESSC}"; LATENCY_BTN="btn-success"
  elif [[ "${LATENCY}" > "2.2" && "${LATENCY}" < "3.8" ]]; then
    LATENCYC="${WARNINGC}"; LATENCY_BTN="btn-warning"
  else
    LATENCYC="${DANGERC}"; LATENCY_BTN="btn-danger"
  fi
}
