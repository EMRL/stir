#!/usr/bin/env bash
#
# analytics.sh
#
###############################################################################
# Handles functions related to retrieving and parsing Google Analytics
#
# Thanks to https://jacobsalmela.com/2014/08/18/oauth-2-0-google-analytics-desktop-using-geektool-bash-curl/
# for breaking this down and helping us get started
# 
# https://developers.google.com/analytics/devguides/reporting/core/dimsmets for all the metrics
###############################################################################

# Initialize variables
var=(SIZE RND METRIC RESULT GA_HITS GA_PERCENT GA_SEARCHES GA_DURATION \
  GA_SOCIAL ANALYTICSMSG ga_day ga_sequence max_value n a GA_TOTAL ga_)
init_loop

ga_var=(users newUsers percentNewSessions sessionsPerUser sessions bounces bounceRate \
  sessionDuration avgSessionDuration uniqueDimensionCombinations hits \
  organicSearches pageValue entrances entranceRate pageviews \
  pageviewsPerSession uniquePageviews timeOnPage avgTimeOnPage exits \
  exitRate impressions adClicks adCost CPM CPC CTR costPerTransaction \
  costPerGoalConversion costPerConversion RPC ROAS goalStartsAll \
  goalCompletionsAll goalValueAll goalValuePerSession goalConversionRateAll \
  goalAbandonsAll goalAbandonRateAll goalConversionRateAll goalAbandonsAll \
  goalAbandonRateAll pageLoadTime pageLoadSample avgPageLoadTime \
  domainLookupTime avgDomainLookupTime pageDownloadTime avgPageDownloadTime \
  redirectionTime avgRedirectionTime serverConnectionTime \
  avgServerConnectionTime serverResponseTime avgServerResponseTime \
  speedMetricsSample domInteractiveTime avgDomInteractiveTime \
  domContentLoadedTime avgDomContentLoadedTime domLatencyMetricsSample \
  socialInteractions uniqueSocialInteractions socialInteractionsPerSession \
  userTimingValue userTimingSample avgUserTimingValue)

for i in "${ga_var[@]}" ; do
  read -r ga_${i} <<< ""
  echo "ga_${i}" > /dev/null
done

function ga_metrics() {
  array[0]="hits"
  array[1]="percentNewSessions"
  array[2]="organicSearches"
  array[3]="avgSessionDuration"
  array[4]="socialInteractions"
  SIZE="${#array[@]}"
  RND="$(($RANDOM % $SIZE))"
  METRIC="${array[$RND]}"
}

function analytics() {
  # If profile does not exist, skip it all
  if [[ -z "${PROFILEID}" ]]; then
    return
  else
    # Setup the metric we're after
    ga_metrics

    # Update access token
    "${curl_cmd}" -s -d "client_id=${CLIENTID}&client_secret=${CLIENTSECRET}&refresh_token=${REFRESHTOKEN}&grant_type=refresh_token" https://accounts.google.com/o/oauth2/token > "${trash_file}"
    sed -i '/access_token/!d' "${trash_file}"
    ACCESSTOKEN="$(awk -F\" '{print $4}' "${trash_file}")"

    # Grab data from Google
    ga_data

    if [[ "${RND}" == "0" ]]; then
      if [[ "${RESULT}" -gt "499" ]]; then
        ANALYTICSMSG="You had <strong>${SIZE}</strong> hits in the last week. Awesome!"
      else
        ga_fail
      fi
    fi

    if [[ "${RND}" == "1" ]]; then
      # Sometimes Google reports confusion percentages that exceed 
      # 100%, let's kill those results
      if [[ "${SIZE}" -gt "100" ]]; then
        ga_fail
      elif [[ "${SIZE}" -gt "50" ]]; then
        ANALYTICSMSG="Last week <strong>${SIZE}</strong> percent of your users were first time visitors. That\&#39;s great!"
      else
        RESULT="$((100 - ${SIZE}))"
        ANALYTICSMSG="Last week <strong>${RESULT}</strong> percent of your users were return visitors. That\&#39;s great!"
      fi
    fi

    if [[ "${RND}" == "2" ]]; then 
      if [[ "${SIZE}" -ge "30" ]]; then
        ANALYTICSMSG="You had traffic from <strong>${SIZE}</strong> organic searches last week. Not bad!"
      else
        ga_fail     
      fi
    fi

    if [[ "${RND}" == "3" ]]; then 
      RESULT="$((${SIZE} / 60))"
      if [[ "${RESULT}" -gt "2" ]]; then
        ANALYTICSMSG="Last week visitors averaged over <strong>${RESULT}</strong> minutes each on your site. Nice!"
      else
        ga_fail
      fi
    fi

    if [[ "${RND}" == "4" ]]; then 
      if [[ "${SIZE}" -ge "20" ]]; then
        ANALYTICSMSG="Your site had <strong>${SIZE}</strong> social media interactions in the last week!"
      else
        ga_fail
      fi
    fi
  fi
}

function ga_data() {
  RESULT=$(${curl_cmd} -s "https://www.googleapis.com/analytics/v3/data/ga?ids=ga:$PROFILEID&metrics=ga:$METRIC&start-date=$GASTART&end-date=$GAEND&access_token=$ACCESSTOKEN" | tr , '\n' | grep -a "\"ga:$METRIC\":" | cut -d'"' -f4)
  SIZE="$(printf "%.0f\n" "${RESULT}")"

  # TODO: Make this a proper loop
  if [[ "${PROJSTATS}" == "1" ]]; then 
    GA_HITS=$(${curl_cmd} -s "https://www.googleapis.com/analytics/v3/data/ga?ids=ga:$PROFILEID&metrics=ga:hits&start-date=$GASTART&end-date=$GAEND&access_token=$ACCESSTOKEN" | tr , '\n' | grep -a "\"ga:hits\":" | cut -d'"' -f4)
    GA_PERCENT=$(${curl_cmd} -s "https://www.googleapis.com/analytics/v3/data/ga?ids=ga:$PROFILEID&metrics=ga:percentNewSessions&start-date=$GASTART&end-date=$GAEND&access_token=$ACCESSTOKEN" | tr , '\n' | grep -a "\"ga:percentNewSessions\":" | cut -d'"' -f4)
    GA_SEARCHES=$(${curl_cmd} -s "https://www.googleapis.com/analytics/v3/data/ga?ids=ga:$PROFILEID&metrics=ga:organicSearches&start-date=$GASTART&end-date=$GAEND&access_token=$ACCESSTOKEN" | tr , '\n' | grep -a "\"ga:organicSearches\":" | cut -d'"' -f4)
    GA_DURATION=$(${curl_cmd} -s "https://www.googleapis.com/analytics/v3/data/ga?ids=ga:$PROFILEID&metrics=ga:avgSessionDuration&start-date=$GASTART&end-date=$GAEND&access_token=$ACCESSTOKEN" | tr , '\n' | grep -a "\"ga:avgSessionDuration\":" | cut -d'"' -f4)
    GA_SOCIAL=$(${curl_cmd} -s "https://www.googleapis.com/analytics/v3/data/ga?ids=ga:$PROFILEID&metrics=ga:socialInteractions&start-date=$GASTART&end-date=$GAEND&access_token=$ACCESSTOKEN" | tr , '\n' | grep -a "\"ga:socialInteractions\":" | cut -d'"' -f4)

    # Make sure we're only dealing with integers
    GA_PERCENT="$(printf "%.0f\n" "${GA_PERCENT}")"
    GA_DURATION="$(printf "%.0f\n" "${GA_DURATION}")"
  fi
}

function ga_data_loop() {
  # Setup variables to process
  console "${GASTART} - ${GAEND}"
  ga_var=(users newUsers percentNewSessions sessionsPerUser sessions bounces bounceRate \
    sessionDuration avgSessionDuration uniqueDimensionCombinations hits \
    organicSearches pageValue entrances entranceRate pageviews \
    pageviewsPerSession uniquePageviews timeOnPage avgTimeOnPage exits \
    exitRate impressions adClicks adCost CPM CPC CTR costPerTransaction \
    costPerGoalConversion costPerConversion RPC ROAS goalStartsAll \
    goalCompletionsAll goalValueAll goalValuePerSession goalConversionRateAll \
    goalAbandonsAll goalAbandonRateAll goalConversionRateAll goalAbandonsAll \
    goalAbandonRateAll pageLoadTime pageLoadSample avgPageLoadTime \
    domainLookupTime avgDomainLookupTime pageDownloadTime avgPageDownloadTime \
    redirectionTime avgRedirectionTime serverConnectionTime \
    avgServerConnectionTime serverResponseTime avgServerResponseTime \
    speedMetricsSample domInteractiveTime avgDomInteractiveTime \
    domContentLoadedTime avgDomContentLoadedTime domLatencyMetricsSample \
    socialInteractions uniqueSocialInteractions socialInteractionsPerSession \
    userTimingValue userTimingSample avgUserTimingValue)

  # Start the loop
  for i in "${ga_var[@]}" ; do
    RESULT=$(${curl_cmd} -s "https://www.googleapis.com/analytics/v3/data/ga?ids=ga:$PROFILEID&metrics=ga:${i}&start-date=$GASTART&end-date=$GAEND&access_token=$ACCESSTOKEN" | tr , '\n\n' | grep -a "\"ga:${i}\":" | cut -d'"' -f4)

    # Workaround for buggy Google shit
    until [[ "${RESULT}" =~ ^[0-9]+([.][0-9]+)?$ ]];
    do
      RESULT=$(${curl_cmd} -s "https://www.googleapis.com/analytics/v3/data/ga?ids=ga:$PROFILEID&metrics=ga:${i}&start-date=$GASTART&end-date=$GAEND&access_token=$ACCESSTOKEN" | tr , '\n\n' | grep -a "\"ga:${i}\":" | cut -d'"' -f4)
    done

    # Round to two decimal places if needed
    if [[ "${RESULT}" = *"."* ]]; then
      RESULT="$(printf '%0.2f\n' "${RESULT}")"
    fi
    # Output trace
    trace "${i}: ${RESULT}"
  done
}

###############################################################################
# ga_over_time()
#   Collects Google Analytics data over a certain period of time
#
# Arguments:
#   [metric]    Defines the metric you wish to get from Google's API. Examples
#               include 'sessions', 'hits', etc. Refere to Google API docs at
#               https://developers.google.com/analytics/devguides/reporting/core/dimsmets 
#   [days]      The number of days for which to gather analytics data.
#
# Returns:  
#   None
###############################################################################  
function ga_over_time() {
  if [[ -z "${PROFILEID}" ]] || [[ -z "${gnuplot_cmd}" ]]; then
    return
  else
    # Process arguments
    if [[ -n "$2" ]]; then
      GASTART="$(date -I -d "$GAEND - $2 day")"
    fi

    # Make sure temp directory exists
    if [[ ! -d "${stat_dir}" ]]; then
      umask 077 && mkdir ${stat_dir} &> /dev/null
    fi
    
    # Setup variables
    ga_day="${GAEND}"
    day="0"
    METRIC="${1}"
    ga_sequence=""
    max_value=""

    # Flush csv
    [[ -f "${trash_file}" ]] && rm "${trash_file}"

    while [ "$ga_day" != "${GASTART}" ]; do 
      RESULT=$(${curl_cmd} -s "https://www.googleapis.com/analytics/v3/data/ga?ids=ga:$PROFILEID&metrics=ga:${METRIC}&start-date=$ga_day&end-date=$ga_day&access_token=$ACCESSTOKEN" | tr , '\n' | grep -a "\"ga:$METRIC\":" | cut -d'"' -f4);
      
      # Workaround for buggy Google shit
      until [[ "${RESULT}" =~ ^[0-9]+([.][0-9]+)?$ ]];
      do
        RESULT=$(${curl_cmd} -s "https://www.googleapis.com/analytics/v3/data/ga?ids=ga:$PROFILEID&metrics=ga:${METRIC}&start-date=$ga_day&end-date=$ga_day&access_token=$ACCESSTOKEN" | tr , '\n' | grep -a "\"ga:$METRIC\":" | cut -d'"' -f4)
      done

      # Make sure we're only dealing with integers
      RESULT="$(printf "%.0f\n" "${RESULT}")"; dot
      
      # Add to total
      let ga_${METRIC}+="${RESULT}"
      
      # Store the values 
      declare "$1_${day}"="${RESULT}"
      ga_sequence="${ga_sequence}${RESULT} "
      day="$((day+1))"
      ga_day="$(date -I -d "$ga_day - 1 day")"
    done
  
    # Create percentage array, this is pretty much obsolete now since 
    # we're using gnuplot
    ga_sequence="$(echo -e "${ga_sequence}" | sed -e 's/[[:space:]]*$//')"
    IFS=', ' read -r -a a <<< "${ga_sequence}"

    for i in ${a[@]}; do
      if [[ $i -gt $max_value ]]; then 
        max_value=$i
      fi
    done

    # Calculate
    for ((n=0; n < $2; n++)); do 
      var="$1_$n"; var_percent="$1_percent_$n"

      # Calculating percent while zero was causing nasty bugs
      if [[ -n "${!var}" ]] && [[ "${!var}" != "0" ]]; then
        var_percent=$(awk "BEGIN { pc=100*${!var}/${max_value}; i=int(pc); print (pc-i<0.5)?i:i+1 }")
      else
        var_percent="0"
      fi
      # trace "100*${!var}/${max_value} = ${var_percent}%"

      # Store values
      eval $1_$n="${!var}"
      eval $1_percent_$n="${var_percent}"
      this_day=$(date '+%a' -d "$n days ago")
      echo -e "${this_day}, ${!var}, ${var_percent}" >> "${trash_file}"

      if [[ "${PROJSTATS}" == "1" ]]; then
        sed -i -e "s^{{$1_$n}}^${!var}^g" \
          -e "s^{{$1_percent_$n}}^${var_percent}^g" \
          -e "s^{{$1_date_$n}}^${this_day}^g" \
          "${html_file}"
      fi    
    done

    tac "${trash_file}" > ${stat_dir}/"${METRIC}".csv

    ${gnuplot_cmd} -p << EOF
    set encoding utf8
    set terminal png enhanced size 1280,600
    primary = "${CHARTC}"; 
    secondary = "${SECONDARYC}";
    info = "${INFOC}";
    default = "${DEFAULTC}";
    set key off
    set datafile separator ","
    set output '${stat_dir}/${METRIC}.png'
    set boxwidth 0.5
    set style fill transparent solid 0.1 noborder
    set samples 1000
    set style line 100 lt 1 lc rgb secondary lw 1
    set style line 101 lt 0.5 lc rgb secondary lw 1
    set grid mytics ytics ls 100, ls 101
    set grid mxtics xtics ls 100, ls 101
    set style line 11 lc rgb default lt 1 lw 3
    set border 3 back ls 11
    set tics out nomirror
    
    # PNG
    set terminal png enhanced size 1280,600
    set output '${stat_dir}/${METRIC}.png'
    plot '${stat_dir}/${METRIC}.csv' using 2:xtic(1) smooth bezier with lines lw 2 lc rgb info,\
      "" using 2:xtic(1) with linespoints lw 3 lc rgb primary pointtype 7 pointsize 3

    # SVG
    set terminal svg dynamic enhanced size 1280,600
    set output '${stat_dir}/${METRIC}.svg'
    plot '${stat_dir}/${METRIC}.csv' using 2:xtic(1) smooth bezier with lines lw 2 lc rgb info,\
      "" using 2:xtic(1) with linespoints lw 3 lc rgb primary pointtype 7 pointsize 3
EOF
fi
}

# If no other results are worth displaying, fall back to displaying hits
function ga_fail() {
  METRIC="hits"
  ga_data
  ANALYTICSMSG="You had <strong>${SIZE}</strong> hits in the last week."
}

function ga_test() {
  empty_line
  if [[ -z "${CLIENTID}" ]] || [[ -z "${CLIENTSECRET}" ]];  then
    warning "Define API project"
    console "Analytics API project not defined. Check https://console.developers.google.com/"
    quiet_exit
  else
    console "CLIENTID=${CLIENTID}"
    console "CLIENTSECRET=${CLIENTSECRET}"
  fi

  if [[ -z "${AUTHORIZATIONCODE}" ]]; then
    empty_line; warning "Authorization required"
    console "Point your browser to this link: https://accounts.google.com/o/oauth2/auth?scope=https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fanalytics&redirect_uri=${REDIRECTURI}&response_type=code&client_id=${CLIENTID}"
    quiet_exit
  else
    console "AUTHORIZATIONCODE=${AUTHORIZATIONCODE}"
  fi

  if [[ -z "${ACCESSTOKEN}" ]] || [[ -z "${REFRESHTOKEN}" ]]; then
    empty_line; warning "Create an access token"
    console "Run this command: curl -H \"Content-Type: application/x-www-form-urlencoded\" -d code=${AUTHORIZATIONCODE} -d client_id=${CLIENTID} -d client_secret=${CLIENTSECRET} -d redirect_uri=${REDIRECTURI} -d grant_type=authorization_code https://accounts.google.com/o/oauth2/token"
    quiet_exit
  else
    console "ACCESSTOKEN=${ACCESSTOKEN}"
    console "REFRESHTOKEN=${REFRESHTOKEN}"
  fi

  if [[ -z "${PROFILEID}" ]]; then
    empty_line; warning "Missing Profile ID"
    console "Your project's profile ID is not defined."
    quiet_exit
  else
    console "PROFILEID=${PROFILEID}"
  fi

  if [[ -z "${REDIRECTURI}" ]]; then 
    warning "Missing Redirect URI"
    console "Generally your Redirect URI will be set to http://localhost"
    quiet_exit
  else
    console "REDIRECTURI=${REDIRECTURI}"
  fi

  notice "Refreshing token..."
  "${curl_cmd}" -s -d "client_id=${CLIENTID}&client_secret=${CLIENTSECRET}&refresh_token=${REFRESHTOKEN}&grant_type=refresh_token" https://accounts.google.com/o/oauth2/token > "${trash_file}"
  sed -i '/access_token/!d' "${trash_file}"
  ACCESSTOKEN="$(awk -F\" '{print $4}' "${trash_file}")"
  echo "${ACCESSTOKEN}"

  ga_data_loop
  return
}
