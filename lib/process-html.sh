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
  [[ -z "${DEVURL}" ]] && sed -i '/DEVURL/d' "${html_file}"
  [[ -z "${PRODURL}" ]] && sed -i '/PRODURL/d' "${html_file}"
  [[ -z "${UPTIME}" ]] && sed -i '/UPTIME/d' "${html_file}"
  [[ -z "${LATENCY}" ]] && sed -i '/LATENCY/d' "${html_file}"  
  [[ -z "${SCAN_MSG}" ]] && sed -i '/SCAN_MSG/d' "${html_file}" 
  [[ -z "${LAST_BACKUP}" ]] && sed -i '/LAST_BACKUP/d' "${html_file}" 
  [[ -z "${PROJCLIENT}" ]] && sed -i 's/()//' "${html_file}"
  [[ -z "${CLIENTLOGO}" ]] && sed -i '/CLIENTLOGO/d' "${html_file}"
  [[ -z "${CLIENTCONTACT}" ]] && sed -i '/CLIENTCONTACT/d' "${html_file}"
  [[ -z "${notes}" ]] && sed -i '/NOTES/d' "${html_file}"
  [[ -z "${SMOOCHID}" ]] && sed -i '/SMOOCHID/d' "${html_file}"
  [[ -z "${COMMITHASH}" ]] && sed -i '/COMMITHASH/d' "${html_file}"
  [[ -z "${NEWS_URL}" ]] && sed -i '/RSS_NEWS/d' "${html_file}"

  # Clean out dashboard nav menu
  [[ -z "${SCAN_MSG}" ]] && sed -i '/SCAN_NAV/d' "${html_file}"
  [[ -z "${FIREWALL_STATUS}" ]] && sed -i '/FIREWALL_NAV/d' "${html_file}"
  [[ -z "${BACKUP_STATUS}" ]] && sed -i '/BACKUP_NAV/d' "${html_file}"
  [[ -z "${PROFILEID}" ]] && sed -i '/ENGAGEMENT_NAV/d' "${html_file}"


  if [[ -z "${RESULT}" ]] || [[ "${RESULT}" == "0" ]] || [[ "${SIZE}" == "0" ]]; then
    sed -i '/BEGIN ANALYTICS/,/END ANALYTICS/d' "${html_file}"
    sed -i '/ANALYTICS/d' "${html_file}"
  fi

  if [[ "${INCLUDE_DETAILS}" != "TRUE" ]]; then
    sed -i '/BEGIN DETAILS/,/END DETAILS/d' "${html_file}"
  else
    if [[ "${ga_impressions}" == "0" ]]; then
      sed -i '/BEGIN ADWORDS/,/END ADWORDS/d' "${html_file}"
    fi
    if [[ "${ga_transactions}" == "0" ]]; then
      sed -i '/BEGIN ECOMMERCE/,/END ECOMMERCE/d' "${html_file}"
    fi
  fi

  if [[ -z "${RSS_URL}" ]]; then
    sed -i -e '/BEGIN WORK RSS/,/END WORK RSS/d' \
      -e '/RSS_URL/d' "${html_file}" \
    "${html_file}"
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
    "${html_file}"

  # Insert commits
  sed_commits=$(echo "sed -e '/{{COMMITS_RECENT}}/ {' -e 'r ${stat_file}' -e 'd' -e '}' -i \"${html_file}\"")
  eval "${sed_commits}"
  
  # Insert scan results
  sed_scan=$(echo "sed -e '/{{SCAN_STATS}}/ {' -e 'r ${scan_html}' -e 'd' -e '}' -i \"${html_file}\"")
  eval "${sed_scan}"

  # Insert backup directory listings
  sed_backup=$(echo "sed -e '/{{BACKUP_FILES}}/ {' -e 'r ${trash_file}' -e 'd' -e '}' -i \"${html_file}\"")
  eval "${sed_backup}"

  # RSS news
  sed -i "s^{{RSS_NEWS}}^${RSS_NEWS}^g" "${html_file}"

  # Setup variables to process
  process_var=(VIEWPORT NOW DEV LOGTITLE USER PROJNAME PROJCLIENT CLIENTLOGO \
    DEVURL PRODURL COMMITURL EXITCODE COMMITHASH USER LOGURL REMOTEURL \
    VIEWPORTPRE PATHTOREPO PROJNAME CLIENTCONTACT DEVURL PRODURL SCAN_MSG \
    SCAN_RESULT SCAN_URL BACKUP_STATUS LAST_BACKUP SMOOCHID DIGESTWRAP \
    GREETING REMOTEURL ANALYTICSMSG COVER WEEKOF UPTIME LATENCY GA_HITS \
    GA_PERCENT GA_SEARCHES GA_DURATION GA_SOCIAL CODE_STATS SCAN_BTN \
    UPTIME_BTN LATENCY_BTN BACKUP_BTN ACTIVITY_NAV STATISTICS_NAV SCAN_NAV \
    ENGAGEMENT_NAV FIREWALL_NAV BACKUP_NAV BACKUP_MSG TOTAL_COMMITS RSS_URL \
    THEME_MODE ENGAGEMENT_DAYS \
    ga_hits  ga_sessions ga_users ga_newUsers ga_sessionsPerUser \
    ga_avgTimeOnPage ga_organicSearches ga_pageviews ga_pageviewsPerSession \
    ga_avgTimeOnPage ga_bounceRate ga_impressions ga_adClicks ga_adCost \
    ga_CPC ga_CTR ga_costPerConversion ga_transactions ga_transactionRevenue \
    ga_revenuePerTransaction ga_revenuePerItem ga_transactionsPerSession \
    ga_transactionsPerUser)

  # Start the loop
  for i in "${process_var[@]}" ; do
    # This is essentially the same as insert_values() [see env-check.sh], we
    #  should consolidate them into one function
    if [[ -n "${!i:-}" ]]; then
      # Uncomment below to help debug
      # [[ "${INCOGNITO}" != "1" ]] && trace "${i}: ${!i}"
      sed_hack=$(echo "sed -i 's^{{${i}}}^${!i}^g' ${html_file}")
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
    -e "s^{{LASTMONTH}}^${last_month}^g" \
    -e "s^{{ANALYTICS_CHART}}^${REMOTEURL}/${APP}/stats/${METRIC}.png^g" \
    "${html_file}"
  }
