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
trace "Loading analytics functions"   

# Initialize variables
read -r SIZE RND METRIC RESULT GA_HITS GA_PERCENT GA_SEARCHES GA_DURATION \
  GA_SOCIAL ANALYTICSMSG ga_var ga_day ga_sequence max_value <<< ""
echo "${SIZE} ${RND} ${METRIC} ${RESULT} ${GA_HITS} ${GA_PERCENT} 
  ${GA_SEARCHES} ${GA_DURATION} ${GA_SOCIAL} ${ANALYTICSMSG} ${ga_var} 
  ${ga_sequence} ${max_value}" > /dev/null

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
  if [[ -n "${PROFILEID}" ]]; then
    # Setup the metric we're after
    ga_metrics

    # Update access token
    curl -s -d "client_id=${CLIENTID}&client_secret=${CLIENTSECRET}&refresh_token=${REFRESHTOKEN}&grant_type=refresh_token" https://accounts.google.com/o/oauth2/token > "${trshFile}"
    sed -i '/access_token/!d' "${trshFile}"
    ACCESSTOKEN="$(awk -F\" '{print $4}' "${trshFile}")"

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
  RESULT=$(curl -s "https://www.googleapis.com/analytics/v3/data/ga?ids=ga:$PROFILEID&metrics=ga:$METRIC&start-date=$GASTART&end-date=$GAEND&access_token=$ACCESSTOKEN" | tr , '\n' | grep "totalsForAllResults" | cut -d'"' -f6)
  SIZE="$(printf "%.0f\n" "${RESULT}")"

  # Make this a proper loop
  if [[ "${PROJSTATS}" == "1" ]]; then 
    GA_HITS=$(curl -s "https://www.googleapis.com/analytics/v3/data/ga?ids=ga:$PROFILEID&metrics=ga:hits&start-date=$GASTART&end-date=$GAEND&access_token=$ACCESSTOKEN" | tr , '\n' | grep "totalsForAllResults" | cut -d'"' -f6)
    GA_PERCENT=$(curl -s "https://www.googleapis.com/analytics/v3/data/ga?ids=ga:$PROFILEID&metrics=ga:percentNewSessions&start-date=$GASTART&end-date=$GAEND&access_token=$ACCESSTOKEN" | tr , '\n' | grep "totalsForAllResults" | cut -d'"' -f6)
    GA_SEARCHES=$(curl -s "https://www.googleapis.com/analytics/v3/data/ga?ids=ga:$PROFILEID&metrics=ga:organicSearches&start-date=$GASTART&end-date=$GAEND&access_token=$ACCESSTOKEN" | tr , '\n' | grep "totalsForAllResults" | cut -d'"' -f6)
    GA_DURATION=$(curl -s "https://www.googleapis.com/analytics/v3/data/ga?ids=ga:$PROFILEID&metrics=ga:avgSessionDuration&start-date=$GASTART&end-date=$GAEND&access_token=$ACCESSTOKEN" | tr , '\n' | grep "totalsForAllResults" | cut -d'"' -f6)
    GA_SOCIAL=$(curl -s "https://www.googleapis.com/analytics/v3/data/ga?ids=ga:$PROFILEID&metrics=ga:socialInteractions&start-date=$GASTART&end-date=$GAEND&access_token=$ACCESSTOKEN" | tr , '\n' | grep "totalsForAllResults" | cut -d'"' -f6)

    # Make sure we're only dealing with integers
    GA_PERCENT="$(printf "%.0f\n" "${GA_PERCENT}")"
    GA_DURATION="$(printf "%.0f\n" "${GA_DURATION}")"
  fi
}

# Just a test for now
function ga_data_loop() {
  # Setup variables to process
  console "${GASTART} - ${GAEND}"
  ga_var=(users newUsers percentNewSessions sessionsPerUser sessions 
    bounceRate avgSessionDuration hits organicSearches pageviews avgTimeOnPage
    avgPageLoadTime avgDomainLookupTime avgServerResponseTime impressions 
    adClicks adCost CPC CTR)

  # Start the loop
  for i in "${ga_var[@]}" ; do
    # This is essentially the same as insert_values() [see env-check.sh], we
    #  should consolidate them into one function
    RESULT=$(curl -s "https://www.googleapis.com/analytics/v3/data/ga?ids=ga:$PROFILEID&metrics=ga:$i&start-date=$GASTART&end-date=$GAEND&access_token=$ACCESSTOKEN" | tr , '\n' | grep "totalsForAllResults" | cut -d'"' -f6)
    
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
#   Collects Gollge Analytics data over a certain period of time
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
  # Process arguments
  if [[ -n "$2" ]]; then
    GASTART="$(date -I -d "$GAEND - $2 day")"
  fi

  # Setup variables
  ga_day="${GAEND}"
  day="0"
  METRIC="${1}"
  
  while [ "$ga_day" != "${GASTART}" ]; do 
    RESULT=$(curl -s "https://www.googleapis.com/analytics/v3/data/ga?ids=ga:$PROFILEID&metrics=ga:${METRIC}&start-date=$ga_day&end-date=$ga_day&access_token=$ACCESSTOKEN" | tr , '\n' | grep "totalsForAllResults" | cut -d'"' -f6)
    trace "${ga_day}: ${RESULT} $1"
    
    # Store the values 
    declare "$1_${day}"="${RESULT}"
    ga_sequence="${ga_sequence}${RESULT} "
    day="$((day+1))"
    ga_day="$(date -I -d "$ga_day - 1 day")"
  done

  # Create percentage array
  ga_sequence="$(echo -e "${ga_sequence}" | sed -e 's/[[:space:]]*$//')"
  trace "Calculating array: ${ga_sequence}"
  IFS=', ' read -r -a a <<< "${ga_sequence}"
  for i in ${a[@]}; do
    if [[ $i -gt $max_value ]]; then 
      max_value=$i
    fi
  done
  trace "Max sequence value=${max_value}"

  # Calculate
  for ((n=0; n < $2; n++)); do 
    var="$1_$n"; var_percent="$1_percent_$n"
    var_percent=$(awk "BEGIN { pc=100*${!var}/${max_value}; i=int(pc); print (pc-i<0.5)?i:i+1 }")
    trace "100*${!var}/${max_value} = ${var_percent}%"
  done
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
    quickExit
  else
    console "CLIENTID=${CLIENTID}"
    console "CLIENTSECRET=${CLIENTSECRET}"
  fi

  if [[ -z "${AUTHORIZATIONCODE}" ]]; then
    empty_line; warning "Authorization required"
    console "Point your browser to this link: https://accounts.google.com/o/oauth2/auth?scope=https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fanalytics&redirect_uri=${REDIRECTURI}&response_type=code&client_id=${CLIENTID}"
    quickExit
  else
    console "AUTHORIZATIONCODE=${AUTHORIZATIONCODE}"
  fi

  if [[ -z "${ACCESSTOKEN}" ]] || [[ -z "${REFRESHTOKEN}" ]]; then
    empty_line; warning "Create an access token"
    console "Run this command: curl -H \"Content-Type: application/x-www-form-urlencoded\" -d code=${AUTHORIZATIONCODE} -d client_id=${CLIENTID} -d client_secret=${CLIENTSECRET} -d redirect_uri=${REDIRECTURI} -d grant_type=authorization_code https://accounts.google.com/o/oauth2/token"
    quickExit
  else
    console "ACCESSTOKEN=${ACCESSTOKEN}"
    console "REFRESHTOKEN=${REFRESHTOKEN}"
  fi

  if [[ -z "${PROFILEID}" ]]; then
    empty_line; warning "Missing Profile ID"
    console "Your project's profile ID is not defined."
    quickExit
  else
    console "PROFILEID=${PROFILEID}"
  fi

  if [[ -z "${REDIRECTURI}" ]]; then 
    warning "Missing Redirect URI"
    console "Generally your Redirect URI will be set to http://localhost"
    quickExit
  else
    console "REDIRECTURI=${REDIRECTURI}"
  fi

  notice "Refreshing token..."
  curl -s -d "client_id=${CLIENTID}&client_secret=${CLIENTSECRET}&refresh_token=${REFRESHTOKEN}&grant_type=refresh_token" https://accounts.google.com/o/oauth2/token > "${trshFile}"
  sed -i '/access_token/!d' "${trshFile}"
  ACCESSTOKEN="$(awk -F\" '{print $4}' "${trshFile}")"
  echo "${ACCESSTOKEN}"

  # Just here for testing
  #ga_data_loop
  empty_line; trace "Day count"
  ga_over_time hits 7
  return

  # Setup the metric we're after
  array[0]="hits"
  array[1]="percentNewSessions"
  array[2]="organicSearches"
  array[3]="avgSessionDuration"
  array[4]="socialInteractions"
  SIZE="${#array[@]}"
  RND="$(($RANDOM % $SIZE))"
  METRIC="${array[$RND]}"

  notice "Retrieving ${METRIC}..."  
  console "Running: printf \"${METRIC} (Last 7 days): \"; curl -s \"https://www.googleapis.com/analytics/v3/data/ga?ids=ga:$PROFILEID&metrics=ga:$METRIC&start-date=$GASTART&end-date=$GAEND&access_token=$ACCESSTOKEN\"" # | tr , '\n' | grep \"totalsForAllResults\" | cut -d'\"' -f6"
  #empty_line; analytics
  sleep 3
  printf "${METRIC} (Last 7 days): "; curl -s "https://www.googleapis.com/analytics/v3/data/ga?ids=ga:$PROFILEID&metrics=ga:$METRIC&start-date=$GASTART&end-date=$GAEND&access_token=$ACCESSTOKEN" | tr , '\n' | grep "totalsForAllResults" | cut -d'"' -f6
  empty_line
  console "Verbose output"
  console "--------------"
  curl -s "https://www.googleapis.com/analytics/v3/data/ga?ids=ga:$PROFILEID&metrics=ga:$METRIC&start-date=$GASTART&end-date=$GAEND&access_token=$ACCESSTOKEN"
  empty_line
}
