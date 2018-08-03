#!/usr/bin/env bash
#
# process-html.sh
#
###############################################################################
# Filters through html templates to inject our project's variables
###############################################################################
trace "Loading html handling"

# Initialize variables 
read -r DEFAULTC PRIMARYC SECONDARYC SUCCESSC INFOC WARNINGC DANGERC SMOOCHID \
  COVER SCANC UPTIMEC LATENCYC LOGC LOGBC sed_commits sed_scan sed_backup <<< ""
echo "${DEFAULTC} ${PRIMARYC} ${SUCCESSC} ${INFOC} ${WARNINGC} ${DANGERC} 
  ${SMOOCHID} ${COVER} ${SCANC} ${UPTIMEC} ${LATENCYC} 
  ${sed_commits} ${sed_scan} ${sed_backup}" > /dev/null

function process_html() {
  # Clean out the stuff we don't need
  [[ -z "${DEVURL}" ]] && sed -i '/<strong>Staging URL:/d' "${htmlFile}"
  [[ -z "${PRODURL}" ]] && sed -i '/PRODURL/d' "${htmlFile}"
  [[ -z "${UPTIME}" ]] && sed -i '/UPTIME/d' "${htmlFile}"
  [[ -z "${LATENCY}" ]] && sed -i '/LATENCY/d' "${htmlFile}"  
  [[ -z "${SCAN_MSG}" ]] && sed -i '/SCAN_MSG/d' "${htmlFile}" 
  [[ -z "${LAST_BACKUP}" ]] && sed -i '/LAST_BACKUP/d' "${htmlFile}" 
  [[ -z "${PROJCLIENT}" ]] && sed -i 's/()//' "${htmlFile}"
  [[ -z "${CLIENTLOGO}" ]] && sed -i '/CLIENTLOGO/d' "${htmlFile}"
  [[ -z "${CLIENTCONTACT}" ]] && sed -i '/CLIENTCONTACT/d' "${htmlFile}"
  [[ -z "${notes}" ]] && sed -i '/NOTES/d' "${htmlFile}"
  [[ -z "${SMOOCHID}" ]] && sed -i '/SMOOCHID/d' "${htmlFile}"

  # Clean out dashboard nav menu
  [[ -z "${SCAN_MSG}" ]] && sed -i '/SCAN_NAV/d' "${htmlFile}"
  [[ -z "${FIREWALL_STATUS}" ]] && sed -i '/FIREWALL_NAV/d' "${htmlFile}"
  [[ -z "${BACKUP_STATUS}" ]] && sed -i '/BACKUP_NAV/d' "${htmlFile}"


  if [[ -z "${RESULT}" ]] || [[ "${RESULT}" == "0" ]] || [[ "${SIZE}" == "0" ]]; then
    sed -i '/BEGIN ANALYTICS/,/END ANALYTICS/d' "${htmlFile}"
    sed -i '/ANALYTICS/d' "${htmlFile}"
  fi

  if [[ -z "${RSS_URL}" ]]; then
    sed -i -e '/BEGIN WORK RSS/,/END WORK RSS/d' \
      -e '/RSS_URL/d' "${htmlFile}" \
    "${htmlFile}"
  else
    sed -i "s^{{RSS_URL}}^${RSS_URL}^g" "${htmlFile}"
  fi

  # Prettify errors, warning, and successes
  sed -i -e '/ERROR/s/$/<\/span>/' \
    -e '/^ERROR/s/^/<span style=\"background-color: {{DANGER}};\">/' \
    -e '/WARNING/s/$/<\/span>/' \
    -e '/^WARNING/s/^/<span style=\"color: {{WARNING}};\">/' \
    -e '/SUCCESS/s/$/<\/span>/' \
    -e '/^SUCCESS/s/^/<span style=\"color: {{SUCCESS}};\">/' \
    -e '/Deployed to/s/$/<\/span>/' \
    -e '/^Deployed to/s/^/<span style=\"color: {{SUCCESS}};\">/' \
    "${htmlFile}"

  # Insert commits
  sed_commits=$(echo "sed -e '/{{COMMITS_RECENT}}/ {' -e 'r ${statFile}' -e 'd' -e '}' -i \"${htmlFile}\"")
  eval "${sed_commits}"
  
  # Insert scan results
  sed_scan=$(echo "sed -e '/{{SCAN_STATS}}/ {' -e 'r ${scan_html}' -e 'd' -e '}' -i \"${htmlFile}\"")
  eval "${sed_scan}"

  # Insert backup directory listings
  sed_backup=$(echo "sed -e '/{{BACKUP_FILES}}/ {' -e 'r ${trshFile}' -e 'd' -e '}' -i \"${htmlFile}\"")
  eval "${sed_backup}"

  # Get to work
  sed -i -e "s^{{VIEWPORT}}^${VIEWPORT}^g" \
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
    -e "s^{{PROJNAME}}^${PROJNAME}^g" \
    -e "s^{{CLIENTCONTACT}}^${CLIENTCONTACT}^g" \
    -e "s^{{DEVURL}}^${DEVURL}^g" \
    -e "s^{{PRODURL}}^${PRODURL}^g" \
    -e "s^{{DEFAULT}}^${DEFAULTC}^g" \
    -e "s^{{PRIMARY}}^${PRIMARYC}^g" \
    -e "s^{{SECONDARY}}^${SECONDARYC}^g" \
    -e "s^{{SUCCESS}}^${SUCCESSC}^g" \
    -e "s^{{INFO}}^${INFOC}^g" \
    -e "s^{{WARNING}}^${WARNINGC}^g" \
    -e "s^{{DANGER}}^${DANGERC}^g" \
    -e "s^{{LOG}}^${LOGC}^g" \
    -e "s^{{LOGBACKGROUND}}^${LOGBC}^g" \
    -e "s^{{SCAN_STATUS}}^${SCANC}^g" \
    -e "s^{{UPTIME_STATUS}}^${UPTIMEC}^g" \
    -e "s^{{LATENCY_STATUS}}^${LATENCYC}^g" \
    -e "s^{{SCAN_MSG}}^${SCAN_MSG}^g" \
    -e "s^{{SCAN_RESULT}}^${SCAN_RESULT}^g" \
    -e "s^{{SCAN_URL}}^${SCAN_URL}^g" \
    -e "s^{{BACKUP_STATUS}}^${BACKUP_STATUS}^g" \
    -e "s^{{LAST_BACKUP}}^${LAST_BACKUP}^g" \
    -e "s^{{SMOOCHID}}^${SMOOCHID}^g" \
    -e "s^{{GRAVATARURL}}^${REMOTEURL}\/${APP}\/avatar^g" \
    -e "s^{{DIGESTWRAP}}^${DIGESTWRAP}^g" \
    -e "s^{{GREETING}}^${GREETING}^g" \
    -e "s^{{REMOTEURL}}^${REMOTEURL}^g" \
    -e "s^{{ANALYTICSMSG}}^${ANALYTICSMSG}^g" \
    -e "s^{{STATURL}}^${REMOTEURL}\/${APP}\/stats^g" \
    -e "s^{{COVER}}^${COVER}^g" \
    -e "s^{{WEEKOF}}^${WEEKOF}^g" \
    -e "s^{{LASTMONTH}}^${LAST_MONTH}^g" \
    -e "s^{{UPTIME}}^${UPTIME}^g" \
    -e "s^{{LATENCY}}^${LATENCY}^g" \
    -e "s^{{GA_HITS}}^${GA_HITS}^g" \
    -e "s^{{GA_PERCENT}}^${GA_PERCENT}^g" \
    -e "s^{{GA_SEARCHES}}^${GA_SEARCHES}^g" \
    -e "s^{{GA_DURATION}}^${GA_DURATION}^g" \
    -e "s^{{GA_SOCIAL}}^${GA_SOCIAL}^g" \
    -e "s^{{CODE_STATS}}^${CODE_STATS}^g" \
    -e "s^{{SCAN_BTN}}^${SCAN_BTN}^g" \
    -e "s^{{UPTIME_BTN}}^${UPTIME_BTN}^g" \
    -e "s^{{LATENCY_BTN}}^${LATENCY_BTN}^g" \
    -e "s^{{BACKUP_BTN}}^${BACKUP_BTN}^g" \
    -e "s^{{ACTIVITY_NAV}}^${ACTIVITY_NAV}^g" \
    -e "s^{{STATISTICS_NAV}}^${STATISTICS_NAV}^g" \
    -e "s^{{SCAN_NAV}}^${SCAN_NAV}^g" \
    -e "s^{{FIREWALL_NAV}}^${FIREWALL_NAV}^g" \
    -e "s^{{BACKUP_NAV}}^${BACKUP_NAV}^g" \
    -e "s^{{BACKUP_MSG}}^${BACKUP_MSG}^g" \
    -e "s^{{TOTAL_COMMITS}}^${TOTAL_COMMITS}^g" \
    -e "s^{{RSS_URL}}^${RSS_URL}^g" \
    "${htmlFile}"
  }
