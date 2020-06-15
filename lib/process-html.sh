#!/usr/bin/env bash
#
# process-html.sh
#
###############################################################################
# Filters through html templates to inject our project's variables
###############################################################################

# Initialize variables 
var=(DEFAULTC PRIMARYC SECONDARYC SUCCESSC INFOC WARNINGC DANGERC SMOOCHID \
  COVER SCANC UPTIMEC LATENCYC LOGC LOGBC sed_commits sed_scan sed_backup \
  process_var v i)
init_loop

function process_html() {
  # Clean out the stuff we don't need
  [[ -z "${DEVURL}" ]] && sed -i '/DEVURL/d' "${htmlFile}"
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
  [[ -z "${COMMITHASH}" ]] && sed -i '/COMMITHASH/d' "${htmlFile}"
  [[ -z "${NEWS_URL}" ]] && sed -i '/RSS_NEWS/d' "${htmlFile}"

  # Clean out dashboard nav menu
  [[ -z "${SCAN_MSG}" ]] && sed -i '/SCAN_NAV/d' "${htmlFile}"
  [[ -z "${FIREWALL_STATUS}" ]] && sed -i '/FIREWALL_NAV/d' "${htmlFile}"
  [[ -z "${BACKUP_STATUS}" ]] && sed -i '/BACKUP_NAV/d' "${htmlFile}"
  [[ -z "${PROFILEID}" ]] && sed -i '/ENGAGEMENT_NAV/d' "${htmlFile}"


  if [[ -z "${RESULT}" ]] || [[ "${RESULT}" == "0" ]] || [[ "${SIZE}" == "0" ]]; then
    sed -i '/BEGIN ANALYTICS/,/END ANALYTICS/d' "${htmlFile}"
    sed -i '/ANALYTICS/d' "${htmlFile}"
  fi

  if [[ -z "${RSS_URL}" ]]; then
    sed -i -e '/BEGIN WORK RSS/,/END WORK RSS/d' \
      -e '/RSS_URL/d' "${htmlFile}" \
    "${htmlFile}"
  #else
  #  sed -i "s^{{RSS_URL}}^${RSS_URL}^g" "${htmlFile}"
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

  # RSS news
  sed -i "s^{{RSS_NEWS}}^${RSS_NEWS}^g" "${htmlFile}"

  # Setup variables to process
  process_var=(VIEWPORT NOW DEV LOGTITLE USER PROJNAME PROJCLIENT CLIENTLOGO \
    DEVURL PRODURL COMMITURL EXITCODE COMMITHASH USER LOGURL REMOTEURL \
    VIEWPORTPRE PATHTOREPO PROJNAME CLIENTCONTACT DEVURL PRODURL SCAN_MSG \
    SCAN_RESULT SCAN_URL BACKUP_STATUS LAST_BACKUP SMOOCHID DIGESTWRAP \
    GREETING REMOTEURL ANALYTICSMSG COVER WEEKOF UPTIME LATENCY GA_HITS \
    GA_PERCENT GA_SEARCHES GA_DURATION GA_SOCIAL CODE_STATS SCAN_BTN \
    UPTIME_BTN LATENCY_BTN BACKUP_BTN ACTIVITY_NAV STATISTICS_NAV SCAN_NAV \
    ENGAGEMENT_NAV FIREWALL_NAV BACKUP_NAV BACKUP_MSG TOTAL_COMMITS RSS_URL \
    ga_hits ga_users ga_newUsers ga_sessions ga_organicSearches ga_pageviews \
    THEME_MODE)

  # Start the loop
  for i in "${process_var[@]}" ; do
    # This is essentially the same as insert_values() [see env-check.sh], we
    #  should consolidate them into one function
    if [[ -n "${!i:-}" ]]; then
      # [[ "${INCOGNITO}" != "1" ]] && trace "${i}: ${!i}"
      sed_hack=$(echo "sed -i 's^{{${i}}}^${!i}^g' ${htmlFile}")
      # Kludgy but works. Ugh.
      eval "${sed_hack}"
    fi
  done

  # Special snowflakes; for some silly reason the variables don't match
  sed -i -e "s^{{VIEWPORT}}^${VIEWPORT}^g" \
    -e "s^{{NOTES}}^${notes}^g" \
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
    -e "s^{{GRAVATARURL}}^${REMOTEURL}\/${APP}\/avatar^g" \
    -e "s^{{STATURL}}^${REMOTEURL}\/${APP}\/stats^g" \
    -e "s^{{LASTMONTH}}^${LAST_MONTH}^g" \
    -e "s^{{ANALYTICS_CHART}}^${REMOTEURL}/${APP}/stats/${METRIC}.png^g" \
    "${htmlFile}"
  }
