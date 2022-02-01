#!/usr/bin/env bash
#
# process-html.sh
#
###############################################################################
# Filters through html templates to inject our project's variables
###############################################################################

# Initialize variables 
var=(DEFAULT_COLOR PRIMARY_COLOR SECONDARY_COLOR SUCCESS_COLOR INFO_COLOR \
  WARNING_COLOR DANGER_COLOR SMOOCHID COVER SCAN_STATUS UPTIME_STATUS \
  LATENCY_STATUS LOG_COLOR LOG_BACKGROUND_COLOR sed_commits sed_scan \
  sed_backup process_var v i)
init_loop

function process_html() {
  # Clean out the stuff we don't need
  [[ -z "${DEV_URL}" ]] && sed -i '/DEV_URL/d' "${html_file}"
  [[ -z "${PROD_URL}" ]] && sed -i '/PROD_URL/d' "${html_file}"
  [[ -z "${UPTIME}" ]] && sed -i '/UPTIME/d' "${html_file}"
  [[ -z "${LATENCY}" ]] && sed -i '/LATENCY/d' "${html_file}"  
  [[ -z "${SCAN_MSG}" ]] && sed -i '/SCAN_MSG/d' "${html_file}" 
  [[ -z "${LAST_BACKUP}" ]] && sed -i '/LAST_BACKUP/d' "${html_file}" 
  [[ -z "${PROJECT_CLIENT}" ]] && sed -i 's/()//' "${html_file}"
  [[ -z "${CLIENT_LOGO}" ]] && sed -i '/CLIENT_LOGO/d' "${html_file}"
  [[ -z "${CLIENT_CONTACT}" ]] && sed -i '/CLIENT_CONTACT/d' "${html_file}"
  [[ -z "${notes}" ]] && sed -i '/NOTES/d' "${html_file}"
  [[ -z "${SMOOCHID}" ]] && sed -i '/SMOOCHID/d' "${html_file}"
  [[ -z "${COMMITHASH}" ]] && sed -i '/COMMITHASH/d' "${html_file}"
  [[ -z "${NEWS_URL}" ]] && sed -i '/RSS_NEWS/d' "${html_file}"

  # Clean out dashboard nav menu
  [[ -z "${SCAN_MSG}" ]] && sed -i '/SCAN_NAV/d' "${html_file}"
  [[ -z "${FIREWALL_STATUS}" ]] && sed -i '/FIREWALL_NAV/d' "${html_file}"
  [[ -z "${BACKUP_STATUS}" ]] && sed -i '/BACKUP_NAV/d' "${html_file}"
  [[ -z "${PROFILE_ID}" ]] && sed -i '/ENGAGEMENT_NAV/d' "${html_file}"

  # If skipping git in digests
  if [[ "${SKIP_GIT}" == "1" ]]; then
    sed -i '/BEGIN STATS BUTTON/,/END STATS BUTTON/d' "${html_file}"
    sed -i '/ANALYTICS_CHART/d' "${html_file}"
    sed -i '/SKIPPING GIT/d' "${html_file}"
  fi

  if [[ -z "${RESULT}" ]] || [[ "${RESULT}" == "0" ]] || [[ "${SIZE}" == "0" ]]; then
    sed -i '/BEGIN ANALYTICS/,/END ANALYTICS/d' "${html_file}"
    sed -i '/ANALYTICS/d' "${html_file}"
  fi

  if [[ "${INCLUDE_DETAILS}" != "TRUE" ]]; then
    sed -i '/BEGIN DETAILS/,/END DETAILS/d' "${html_file}"
  else
    if [[ "${ga_impressions}" == "0" ]]; then
      sed -i '/BEGIN ADS/,/END ADS/d' "${html_file}"
    fi
    if [[ "${ga_transactions}" == "0" ]]; then
      sed -i '/BEGIN ECOMMERCE/,/END ECOMMERCE/d' "${html_file}"
    fi
    if [[ "${mtc_valid}" != "1" ]]; then
      sed -i '/BEGIN EMAIL/,/END EMAIL/d' "${html_file}"
    else
      if [[ -z "${mtc_publishUp_1}" ]]; then
        sed -i '/BEGIN 01_EMAIL/,/END 01_EMAIL/d' "${html_file}"
      fi
      if [[ -z "${mtc_publishUp_2}" ]]; then
        sed -i '/BEGIN 02_EMAIL/,/END 02_EMAIL/d' "${html_file}"
      fi
      if [[ -z "${mtc_publishUp_3}" ]]; then
        sed -i '/BEGIN 03_EMAIL/,/END 03_EMAIL/d' "${html_file}"
      fi
    fi
  fi

  # Strip out RSS if not needed
  if [[ -z "${RSS_URL}" ]]; then
    sed -i -e '/BEGIN WORK RSS/,/END WORK RSS/d' \
      -e '/RSS_URL/d' "${html_file}" \
    "${html_file}"
  fi

  if [[ "${NO_ACTIVITY}" == "1" ]]; then
    sed -i -e '/BEGIN REMOVE IF NO_ACTIVITY/,/END REMOVE IF NO_ACTIVITY/d' \
      -e '/NO_ACTIVITY/d' "${html_file}" \
    "${html_file}"
  fi

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
  process_var=(VIEWPORT NOW DEV LOGTITLE USER PROJECT_NAME PROJECT_CLIENT \
    CLIENT_LOGO DEV_URL PROD_URL COMMITURL EXITCODE COMMITHASH USER LOGURL \
    REMOTE_URL VIEWPORTPRE PATHTOREPO PROJECT_NAME CLIENT_CONTACT DEV_URL \
    PROD_URL SCAN_MSG SCAN_RESULT SCAN_URL BACKUP_STATUS LAST_BACKUP SMOOCHID \
    DIGESTWRAP GREETING REMOTE_URL ANALYTICSMSG COVER WEEKOF UPTIME LATENCY \
    GA_HITS GA_PERCENT GA_SEARCHES GA_DURATION GA_SOCIAL CODE_STATS SCAN_BTN \
    UPTIME_BTN LATENCY_BTN BACKUP_BTN ACTIVITY_NAV STATISTICS_NAV SCAN_NAV \
    ENGAGEMENT_NAV FIREWALL_NAV BACKUP_NAV BACKUP_MSG TOTAL_COMMITS RSS_URL \
    THEME_MODE ENGAGEMENT_DAYS ga_hits  ga_sessions ga_users ga_newUsers \
    ga_sessionsPerUser ga_avgSessionDuration ga_organicSearches ga_pageviews \
    ga_pageviewsPerSession ga_avgTimeOnPage ga_bounceRate ga_impressions \
    ga_adClicks ga_adCost ga_CPC ga_CTR ga_costPerConversion ga_transactions \
    ga_transactionRevenue ga_revenuePerTransaction ga_revenuePerItem \
    ga_transactionsPerSession ga_transactionsPerUser MAUTIC_URL \
    mtc_id_1 mtc_subject_1 mtc_publishUp_1 mtc_sentCount_1 mtc_readCount_1 \
    mtc_readRate_1 mtc_id_2 mtc_subject_2 mtc_publishUp_2 mtc_sentCount_2 \
    mtc_readCount_2 mtc_readRate_2 mtc_id_3 mtc_subject_3 mtc_publishUp_3 \
    mtc_sentCount_3 mtc_readCount_3 mtc_readRate_3 LOG_BACKGROUND_COLOR \
    SUCCESS_COLOR DANGER_COLOR WARNING_COLOR PRIMARY_COLOR)

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
    -e "s^{{DEFAULT}}^${DEFAULT_COLOR}^g" \
    -e "s^{{PRIMARY}}^${PRIMARY_COLOR}^g" \
    -e "s^{{SECONDARY}}^${SECONDARY_COLOR}^g" \
    -e "s^{{INFO}}^${INFO_COLOR}^g" \
    -e "s^{{WARNING}}^${WARNING_COLOR}^g" \
    -e "s^{{DANGER}}^${DANGER_COLOR}^g" \
    -e "s^{{LOG}}^${LOG_COLOR}^g" \
    -e "s^{{LOGBACKGROUND}}^${LOG_BACKGROUND_COLOR}^g" \
    -e "s^{{SCAN_STATUS}}^${SCAN_STATUS}^g" \
    -e "s^{{UPTIME_STATUS}}^${UPTIME_STATUS}^g" \
    -e "s^{{LATENCY_STATUS}}^${LATENCY_STATUS}^g" \
    -e "s^{{GRAVATARURL}}^${REMOTE_URL}\/${APP}\/avatar^g" \
    -e "s^{{STATURL}}^${REMOTE_URL}\/${APP}\/stats^g" \
    -e "s^{{LASTMONTH}}^${last_month}^g" \
    -e "s^{{ANALYTICS_CHART}}^${REMOTE_URL}/${APP}/stats/${METRIC}.png^g" \
    "${html_file}"

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
  }
