#!/usr/bin/env bash
#
# digest.sh
#
###############################################################################
# Handles creating of digest emails
###############################################################################

# Initializa needed variables
var=(DIGEST_WRAP DIGEST_SLACK GREETING NO_ACTIVITY)
init_loop

build_digest_commits() {
  if [[ "${SKIP_GIT}" == "1" ]]; then
    return
  fi

  # Get ready
  DIGEST_WRAP="$(<${stir_path}/html/${HTML_TEMPLATE}/digest/commit.html)"
  > "${stat_file}"

  # If there have been no commits in the last week, skip
  if [[ $(git log --since="7 days ago") ]]; then
    git log --pretty=format:"%n$DIGEST_WRAP<strong>%ncommit <a style=\"color: {{PRIMARY}}; text-decoration: none; font-weight: bold;\" href=\"${REMOTE_URL}/${APP}/%h.html\">%h</a>%nAuthor: %aN%nDate: %aD (%cr)%n%s</td></tr></table>" --since="7 days ago" > "${stat_file}"; dot
    sed -i '/^commit/ s/$/ <\/strong><br>/' "${stat_file}"
    sed -i '/^Author:/ s/$/ <br>/' "${stat_file}"
    sed -i '/^Date:/ s/$/ <br><br>/' "${stat_file}"

    # Look for manual commits and strip their URLs 
    grep -oP "(?<=href=\")[^\"]+(?=\")" "${stat_file}" > "${trash_file}"; dot
    while read URL; do
      CODE=$(${curl_cmd} -o /dev/null --silent --head --write-out '%{http_code}' "$URL")
      if [[ "${CODE}" != "200" ]]; then 
        # sed -i "s,${URL},${REMOTE_URL}/nolog.html,g" "${stat_file}"
        sed -i "s,${URL},${REPO_HOST}/${REPO},g" "${stat_file}"; dot
      fi
    done < "${trash_file}"
  else
    NO_ACTIVITY="1"
  fi
}

check_stats() {
  trace "Future site of stats check"
}

###############################################################################
# build_digest_analytics()
#   Generate the weekly GA4 summary and chart for digest emails.
###############################################################################
build_digest_analytics() {
  # Analytics are optional.
  if [[ -z "${PROFILE_ID}" ]]; then
    return 0
  fi

  GA_HITS=""
  ANALYTICS_MSG=""
  RESULT=""
  METRIC=""

  # Retrieve seven days of GA4 pageviews and generate the chart.
  if ! ga4_over_time "pageviews" 7 ||
     [[ ! -s "${stat_dir}/traffic.png" ]]; then
    warning "Could not generate the weekly GA4 digest chart"
    return 0
  fi

  if [[ ! "${ga_pageviews:-}" =~ ^[0-9]+$ ]]; then
    warning "GA4 returned an invalid pageview total"
    return 0
  fi

  GA_HITS="${ga_pageviews}"
  RESULT="${GA_HITS}"

  ANALYTICS_MSG="Your website had <strong>${GA_HITS}</strong> pageviews last week."

  # render_html() uses METRIC to construct the public chart URL.
  METRIC="traffic"
}


###############################################################################
# ga4_digest_metric()
#   Retrieve and format one GA4 metric for a digest token.
#
# Arguments:
#   [variable] [metric] [count|decimal|percent]
#   [optional filter dimension] [optional filter value]
###############################################################################
ga4_digest_metric() {
  local destination="${1}"
  local metric="${2}"
  local format="${3:-count}"
  local filter_dimension="${4:-}"
  local filter_value="${5:-}"
  local metric_value=""

  if ga4_data "${metric}" "7daysAgo" "yesterday" "" \
    "${filter_dimension}" "${filter_value}"; then

    metric_value="$(
      printf '%s\n' "${ga4_payload}" |
        get_json_value value 1 |
        tr -d '[:space:]'
    )"

    # No rows means zero activity.
    if [[ -z "${metric_value}" &&
          "${ga4_row_count}" == "0" ]]; then
      metric_value="0"
    fi
  fi

  # Avoid displaying unresolved tokens or incorrect zeros
  # when Google returns an error.
  if [[ ! "${metric_value}" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    printf -v "${destination}" '%s' 'N/A'
    return 0
  fi

  case "${format}" in
    count)
      printf -v "${destination}" '%s' \
        "$(awk -v n="${metric_value}" \
          'BEGIN { printf "%.0f", n }')"
      ;;
    decimal)
      printf -v "${destination}" '%s' \
        "$(awk -v n="${metric_value}" \
          'BEGIN { printf "%.2f", n }')"
      ;;
    percent)
      printf -v "${destination}" '%s' \
        "$(awk -v n="${metric_value}" \
          'BEGIN { printf "%.1f", n * 100 }')"
      ;;
  esac
}

###############################################################################
# build_digest_details()
#   Populate detailed GA4 statistics for weekly digest emails.
###############################################################################
build_digest_details() {
  local ga_itemRevenue=""
  local ga_itemsPurchased=""

  if [[ "${INCLUDE_DETAILS}" != "TRUE" ||
        -z "${GA_HITS:-}" ]]; then
    return 0
  fi

  # Traffic and engagement
  ga4_digest_metric ga_users totalUsers count
  ga4_digest_metric ga_newUsers newUsers count
  ga4_digest_metric ga_sessions sessions count
  ga4_digest_metric ga_sessionsPerUser sessionsPerUser decimal
  ga4_digest_metric ga_avgSessionDuration averageSessionDuration decimal
  ga4_digest_metric ga_organicSearches sessions count \
    sessionDefaultChannelGroup "Organic Search"
  ga4_digest_metric ga_pageviewsPerSession screenPageViewsPerSession decimal
  ga4_digest_metric ga_engagedSessions engagedSessions count
  ga4_digest_metric ga_bounceRate bounceRate percent

  # Advertising
  ga4_digest_metric ga_impressions advertiserAdImpressions count

  if [[ "${ga_impressions:-}" =~ ^[1-9][0-9]*$ ]]; then
    ga4_digest_metric ga_adClicks advertiserAdClicks count
    ga4_digest_metric ga_adCost advertiserAdCost decimal
    ga4_digest_metric ga_CPC advertiserAdCostPerClick decimal
    ga4_digest_metric ga_costPerConversion advertiserAdCostPerKeyEvent decimal

    # Calculate click-through rate
    ga_CTR="N/A"

    if [[ "${ga_adClicks:-}" =~ ^[0-9]+$ ]]; then
      ga_CTR="$(awk \
        -v clicks="${ga_adClicks}" \
        -v impressions="${ga_impressions}" \
        'BEGIN { printf "%.1f", 100 * clicks / impressions }')"
    fi
  fi

  # Ecommerce
  ga4_digest_metric ga_transactions ecommercePurchases count

  if [[ "${ga_transactions:-}" =~ ^[1-9][0-9]*$ ]]; then
    ga4_digest_metric ga_transactionRevenue purchaseRevenue decimal
    ga4_digest_metric ga_revenuePerTransaction averagePurchaseRevenue decimal
    ga4_digest_metric ga_itemRevenue itemRevenue decimal
    ga4_digest_metric ga_itemsPurchased itemsPurchased count

    # Average item revenue
    ga_revenuePerItem="N/A"

    if [[ "${ga_itemRevenue:-}" =~ ^[0-9]+([.][0-9]+)?$ ]] &&
       [[ "${ga_itemsPurchased:-}" =~ ^[1-9][0-9]*$ ]]; then

      ga_revenuePerItem="$(awk \
        -v revenue="${ga_itemRevenue}" \
        -v items="${ga_itemsPurchased}" \
        'BEGIN { printf "%.2f", revenue / items }')"
    fi

    # Purchases per session
    ga_transactionsPerSession="N/A"

    if [[ "${ga_sessions:-}" =~ ^[1-9][0-9]*$ ]]; then
      ga_transactionsPerSession="$(awk \
        -v purchases="${ga_transactions}" \
        -v sessions="${ga_sessions}" \
        'BEGIN { printf "%.2f", purchases / sessions }')"
    fi

    # Purchases per user
    ga_transactionsPerUser="N/A"

    if [[ "${ga_users:-}" =~ ^[1-9][0-9]*$ ]]; then
      ga_transactionsPerUser="$(awk \
        -v purchases="${ga_transactions}" \
        -v users="${ga_users}" \
        'BEGIN { printf "%.2f", purchases / users }')"
    fi
  fi
}

build_digest() {
  if [[ -z "${DIGEST_SLACK}" || "${DIGEST_SLACK}" == "FALSE" ]] && [[ -z "${DIGEST_EMAIL}" ]]; then 
    return
  else
    message_state="DIGEST"
    prepare_html_dir
    
    # Collect gravatars for all the authors in this repo
    prepare_author_avatars; dot

    # If configured, setup RSS news
    create_rss_payload; dot
    
    # Generate weekly GA4 analytics
    build_digest_analytics; dot

    # Populate detailed GA4 metrics
    build_digest_details; dot

    # Email marketing stats
    if [[ -n "${MAUTIC_URL}" && -n "${MAUTIC_AUTH}" ]]; then
      mtc_data_loop; dot
    fi

    build_digest_commits

    # If there's no analytics and no commit activity, there's no need for a digest
    if [[ -z "${ANALYTICS_MSG}" ]] && [[ "${NO_ACTIVITY}" == "1" ]]; then
      console " No activity found."
      quiet_exit
    fi

    cat "${stir_path}/html/${HTML_TEMPLATE}/digest/header.html" "${stat_file}" "${stir_path}/html/${HTML_TEMPLATE}/digest/footer.html" > "${html_file}"; dot

    # Randomize a positive Monday thought. Special characters must be escaped 
    # and use character codes
    array[0]="Hope you had a good weekend!"
    array[1]="Alright Monday, let\&#39;s do this."
    array[2]="Oh, hello Monday."
    array[3]="Welcome back, how was your weekend?"
    array[4]="Happy Monday and welcome back!"
    array[5]="Hello and good morning!"
    SIZE="${#array[@]}"
    RND="$(($RANDOM % $SIZE))"
    GREETING="${array[$RND]}"

    render_html; dot

    # Strip out useless analytics results
    if [[ -z "${RESULT}" ]] || [[ "${RESULT}" == "0" ]] || [[ "${SIZE}" == "0" ]]; then
      sed -i '/ANALYTICS/d' "${html_file}"
    # else
      if [[ "${METRIC}" == "pageviews" ]] && [[ "${RESULT}" -lt "200" ]]; then
        sed -i '/ANALYTICS/d' "${html_file}"
      fi
    fi   

    # Strip out Mautic stuff if not needed
    if [[ -z "${mtc_sentCount_1}" || "${mtc_sentCount_1}" == "0" ]]; then
      sed -i '/BEGIN 01_EMAIL/,/END 01_EMAIL/d' "${html_file}"
    fi
    if [[ -z "${mtc_sentCount_2}" || "${mtc_sentCount_2}" == "0" ]]; then
      sed -i '/BEGIN 02_EMAIL/,/END 02_EMAIL/d' "${html_file}"
    fi
    if [[ -z "${mtc_sentCount_3}" || "${mtc_sentCount_3}" == "0" ]]; then
      sed -i '/BEGIN 03_EMAIL/,/END 03_EMAIL/d' "${html_file}"
    fi

    # Get the email payload ready
    digest_payload=$(<"${html_file}")
  fi
}
