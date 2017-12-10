#!/bin/bash
#
# monitor.sh
#
###############################################################################
# Uses PHP Server Monitor and an add-on API to retrieve a production server's 
# uptime and latency
###############################################################################
trace "Loading server monitoring"

function server_monitor() {
	# Don't bother unless all the needed variables are declared
	if [[ -n "${MONITORURL}" ]] && [[ -n "${MONITORUSER}" ]] && [[ -n "${SERVERID}" ]] && [[ -n "${MONITORPASS}" ]]; then
		# What kind of log is this?
		if [[ "${REPORT}" == "1" ]]; then
			# Last 30 days; this will not correlate exactly with the time range of the report 
			# which is dealing with the last calendar month, but oh well we get what we pay
			# for. The PHP Monitor API has no ability to look up results in that way 
			MONITORHOURS="720"
		else
			# Default to last 7 days
			MONITORHOURS="168"
		fi
		server_monitor_log
		trace "Uptime: ${UPTIME} / Latency: ${LATENCY} (avg. over last ${MONITORHOURS} hours)"
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
	MONITORHOURS="168"
	server_monitor_log
  console "API: ${MONITORAPI}"	
	notice "Results (last 7 days)"
	console "Uptime: ${UPTIME}%"
	console "Latency: ${LATENCY}s"
}

function server_monitor_log() {
	# :oad the password and setup the curl command
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

	# Latency
	LATENCY="$(grep -Po '"average_latency":.*?[^\\]",' ${trshFile})"
	LATENCY="$(cut -d ',' -f 1 <<< "${LATENCY}")"
	# Isolate the value we need
	LATENCY="$(sed 's/^[^:]*://g' <<< "${LATENCY}")"
	# Round to two decimal places
	LATENCY="$(printf '%0.2f\n' "${LATENCY}")"
}
