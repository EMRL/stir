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
  GA_SOCIAL ANALYTICSMSG <<< ""
echo "${SIZE} ${RND} ${METRIC} ${RESULT} ${GA_HITS} ${GA_PERCENT} ${GA_SEARCHES} 
  ${GA_DURATION} ${GA_SOCIAL} ${ANALYTICSMSG}" > /dev/null

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

# If no other results are worht displaying, fall back to displaying hits
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
