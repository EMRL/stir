#!/bin/bash
#
# analytics.sh
#
# Handles functions related to retrieving and parsing Google Analytics.
trace "Loading analytics functions"   

function analyticsTest() {
	emptyLine
	if [[ -z "${CLIENTID}" ]] || [[ -z "${CLIENTSECRET}" ]];  then
		warning "Define API project"
		console "Analytics API project not defined. Check https://console.developers.google.com/"
		quickExit
	else
		console "CLIENTID=${CLIENTID}"
		console "CLIENTSECRET=${CLIENTSECRET}"
	fi

	if [[ -z "${AUTHORIZATIONCODE}" ]]; then
		emptyLine; warning "Authorization required"
		console "Point your browser to this link: https://accounts.google.com/o/oauth2/auth?scope=https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fanalytics&redirect_uri=${REDIRECTURI}&response_type=code&client_id=${CLIENTID}"
		quickExit
	else
		console "AUTHORIZATIONCODE=${AUTHORIZATIONCODE}"
	fi

	if [[ -z "${ACCESSTOKEN}" ]] || [[ -z "${REFRESHTOKEN}" ]]; then
		emptyLine; warning "Create an access token"
		console "Run this command: curl -H \"Content-Type: application/x-www-form-urlencoded\" -d code=${AUTHORIZATIONCODE} -d client_id=${CLIENTID} -d client_secret=${CLIENTSECRET} -d redirect_uri=${REDIRECTURI} -d grant_type=authorization_code https://accounts.google.com/o/oauth2/token"
		quickExit
	else
		console "ACCESSTOKEN=${ACCESSTOKEN}"
		console "REFRESHTOKEN=${REFRESHTOKEN}"
	fi

	if [[ -z "${PROFILEID}" ]]; then
		emptyLine; warning "Missing Profile ID"
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
	SIZE="${#array[@]}"
	RND="$(($RANDOM % $SIZE))"
	METRIC="${array[$RND]}"

	notice "Retrieving ${METRIC}..."	
	console "Running: printf \"${METRIC} (Last 7 days): \"; curl -s \"https://www.googleapis.com/analytics/v3/data/ga?ids=ga:$PROFILEID&metrics=ga:$METRIC&start-date=$GASTART&end-date=$GAEND&access_token=$ACCESSTOKEN\"" # | tr , '\n' | grep \"totalsForAllResults\" | cut -d'\"' -f6"
	#emptyLine; analytics
	sleep 3
	printf "${METRIC} (Last 7 days): "; curl -s "https://www.googleapis.com/analytics/v3/data/ga?ids=ga:$PROFILEID&metrics=ga:$METRIC&start-date=$GASTART&end-date=$GAEND&access_token=$ACCESSTOKEN" | tr , '\n' | grep "totalsForAllResults" | cut -d'"' -f6
	emptyLine
	console "Verbose output"
	console "--------------"
	curl -s "https://www.googleapis.com/analytics/v3/data/ga?ids=ga:$PROFILEID&metrics=ga:$METRIC&start-date=$GASTART&end-date=$GAEND&access_token=$ACCESSTOKEN"
	emptyLine
}

function analytics() {
	# Setup the metric we're after
	array[0]="hits"
	array[1]="percentNewSessions"
	array[2]="organicSearches"
	array[3]="avgSessionDuration"
	SIZE="${#array[@]}"
	RND="$(($RANDOM % $SIZE))"
	METRIC="${array[$RND]}"

	# Update access token
	curl -s -d "client_id=${CLIENTID}&client_secret=${CLIENTSECRET}&refresh_token=${REFRESHTOKEN}&grant_type=refresh_token" https://accounts.google.com/o/oauth2/token > "${trshFile}"
	sed -i '/access_token/!d' "${trshFile}"
 	ACCESSTOKEN="$(awk -F\" '{print $4}' "${trshFile}")"

	# Grab data from Google
	RESULT=$(curl -s "https://www.googleapis.com/analytics/v3/data/ga?ids=ga:$PROFILEID&metrics=ga:$METRIC&start-date=$GASTART&end-date=$GAEND&access_token=$ACCESSTOKEN" | tr , '\n' | grep "totalsForAllResults" | cut -d'"' -f6)

	# Round if off
	SIZE="$(printf "%.0f\n" "${RESULT}")"

	if [[ "${RND}" == "0" ]]; then 
		ANALYTICSMSG="You had <strong>${SIZE}</strong> hits in the last week. Awesome!"
	fi

	if [[ "${RND}" == "1" ]]; then 
		ANALYTICSMSG="Last week <strong>${SIZE}</strong> percent of your users were first time visitors. That's great!"
	fi

	if [[ "${RND}" == "2" ]]; then 
		ANALYTICSMSG="You had traffic come in from <strong>${SIZE}</strong> organic searches last week. Not bad!"
	fi

	if [[ "${RND}" == "3" ]]; then 
		RESULT="$((${SIZE} / 60))"
		ANALYTICSMSG="This week your users spent an average of <strong>${RESULT}</strong> minutes each on your site. Nice!"
	fi
}
