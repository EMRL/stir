#!/usr/bin/env bash
#
# statistics.sh
#
###############################################################################
# Generate HTML statistics pages
###############################################################################

# Initialize variables
var=(DB_API_TOKEN DB_BACKUP_PATH LAST_BACKUP BACKUP_STATUS CODE_STATS \
  BACKUP_BTN LATENCY_BTN UPTIME_BTN SCAN_BTN COMMITS_RECENT  \
  repo_charts ACTIVITY_NAV STATISTICS_NAV SCAN_NAV ENGAGEMENT_NAV \
  FIREWALL_NAV BACKUP_NAV SCAN_STATS FIREWALL_STATUS BACKUP_MSG \
  BACKUP_FILES TOTAL_COMMITS RSS_URL ga_hits ga_users ga_newUsers ga_sessions \
  ga_organicSearches ga_pageviews ENGAGEMENT_DAYS)
init_loop

function project_stats() {
  hash gitchart 2>/dev/null || {
  error "gitchart not installed." 
  }

  if [[ "${REMOTELOG}" == "TRUE" ]]; then
  # Check for approval queue
  queue_check

    # Setup up tmp work folder
    #if [[ ! -d "${statDir}" ]]; then
    #  umask 077 && mkdir "${statDir}" &> /dev/null
    #fi

    # Prep assets
    cp -R "${deployPath}/html/${HTMLTEMPLATE}/stats/css" "${statDir}/"
    cp -R "${deployPath}/html/${HTMLTEMPLATE}/stats/fonts" "${statDir}/"
    cp -R "${deployPath}/html/${HTMLTEMPLATE}/stats/js" "${statDir}/"

    notice "Generating files..."

    # Define dashboard navigation
    assign_nav

    # Collect gravatars for all the authors in this repo
    get_avatars

    # Start building the main stat overview dashboard
    # Attempt to get analytics
    analytics

    # Code stats
    CODE_STATS=$(git log --author="${FULLUSER}" --pretty=tformat: --numstat | \
      awk '{ add += $1 ; subs += $2 ; loc += $1 - $2 } END { printf \
      "Total lines of code: %s<br>(+%s added | -%s deleted)\n",loc,add,subs }' -)
   
    # Get commits
    get_commits 6
    validate_urls "${statFile}"

    # Process the HTML
    cat "${deployPath}/html/${HTMLTEMPLATE}/stats/index.html" > "${htmlFile}"
    process_html

    cat "${htmlFile}" > "${statDir}/index.html"

    # Create SVG charts
    # Spinners commented out for now, causing issues when running from a crontab
    repo_charts=(authors commits_day_week commits_hour_day commits_hour_week \
      commits_month commits_year commits_year_month files_type)
    for i in "${repo_charts[@]}" ; do
      /usr/bin/gitchart -r "${WORKPATH}/${APP}" "${i}" "${statDir}/${i}.svg" &>> /dev/null
      sed -i "s/#9999ff/${CHARTC}/g" "${statDir}/${i}.svg" 
      sed -i 's/Consolas,"Liberation Mono",Menlo,Courier,monospace/Roboto, Helvetica, Arial, sans-serif/g' "${statDir}/${i}.svg"
    done #&
    #spinner $!

    # Create sub pages
    project_activity #& spinner $!
    project_statistics #& spinner $!
    project_firewall #& spinner $!
    project_backup #& spinner $!
    project_engagement #& spinner $!

    # Filter CSS
    project_css #& spinner $!

    # Post files
    postLog #& spinner $!
  fi
}

function project_activity() {
  # Grab the total number of commits
  TOTAL_COMMITS=$(git rev-list --count ${MASTER})
  get_commits "${TOTAL_COMMITS}"
  validate_urls "${statFile}"

  # Process the HTML
  cat "${deployPath}/html/${HTMLTEMPLATE}/stats/activity.html" > "${htmlFile}"
  process_html; cat "${htmlFile}" > "${statDir}/activity.html"
}

function project_statistics() {
  # Process the HTML
  cat "${deployPath}/html/${HTMLTEMPLATE}/stats/stats.html" > "${htmlFile}"
  process_html; cat "${htmlFile}" > "${statDir}/stats.html"
}

# This is a special snowflake for now, called from within scan_host()
function project_scan(){
  
  #if [[ ! -d "${statDir}" ]]; then
  #  umask 077 && mkdir ${statDir} &> /dev/null
  #fi
  
  SCAN_STATS=$(<${scan_html})
  cat "${deployPath}/html/${HTMLTEMPLATE}/stats/scan.html" > "${htmlFile}"
  process_html; cat "${htmlFile}" > "${statDir}/scan.html"
}

function project_firewall() {
  # Process the HTML
  cat "${deployPath}/html/${HTMLTEMPLATE}/stats/firewall.html" > "${htmlFile}"
  process_html; cat "${htmlFile}" > "${statDir}/firewall.html"
}

function project_engagement() {
  if [[ -z "${PROFILEID}" ]]; then
    trace "Google Analytics not configured"
    return
  fi
  
  cat "${deployPath}/html/${HTMLTEMPLATE}/stats/engagement.html" > "${htmlFile}"

  # How many days of analytics to display?
  if [[ -z "${ENGAGEMENT_DAYS}" ]]; then
    ENGAGEMENT_DAYS="7"
  fi

  ga_var=(hits users newUsers sessions organicSearches pageviews)
  # Start the loop
  for i in "${ga_var[@]}" ; do
    ga_over_time ${i} ${ENGAGEMENT_DAYS}
  done

  # Process the HTML
  process_html; 
  cat "${htmlFile}" > "${statDir}/engagement.html"
}

function project_css() {
  # Process the CSS files
  cat "${deployPath}/html/${HTMLTEMPLATE}/stats/css/${THEME_MODE}.css" > "${htmlFile}"
  process_html; cat "${htmlFile}" > "${statDir}/css/${THEME_MODE}.css"
}

function project_backup() {
  # Get file directory
  #echo "${BACKUP_FILES}" > "${trshFile}"

  echo "${BACKUP_FILES}" | grep -Po '"path_display":.*?[^\\]",' > "${trshFile}"
  sed -i 's/\"path_display\": \"//g' "${trshFile}"
  sed -i 's/\",//g' "${trshFile}"
  sed -i 's/$/<hr>/' "${trshFile}"
  BACKUP_FILES=$(tac ${trshFile})
  echo "${BACKUP_FILES}" > "${trshFile}"

  # Process the HTML
  cat "${deployPath}/html/${HTMLTEMPLATE}/stats/backup.html" > "${htmlFile}"
  process_html; cat "${htmlFile}" > "${statDir}/backup.html"
}

function check_backup() {
  # Are we setup?
  if [[ -z "${DB_BACKUP_PATH}" ]] || [[ -z "${DB_API_TOKEN}" ]]; then
    return
  else 
    # Examine the Dropbox backup directory
    curl -s -X POST https://api.dropboxapi.com/2/files/list_folder \
    --header "Authorization: Bearer ${DB_API_TOKEN}" \
    --header "Content-Type: application/json" \
    --data "{\"path\": \"${DB_BACKUP_PATH}\",\"recursive\": false,
      \"include_media_info\": false,\"include_deleted\": false,
      \"include_has_explicit_shared_members\": false}" > "${trshFile}"

    # Check for what we might assume is error output
    if [[ $(grep "error" "${trshFile}") ]]; then
      warning "Error in backup configuration"
      return
    fi

    # Store file list for later
    BACKUP_FILES="$(<${trshFile})" 

    # Start the loop
    for i in $(seq 0 365)
      do 
      var="$(date -d "${i} day ago" +"%Y-%m-%d")"
      if [[ $(grep "${var}" "${trshFile}") ]]; then
        # Assume success
        BACKUP_STATUS="${SUCCESSC}"
        BACKUP_BTN="btn-success"
        if [[ "${i}" == "0" ]]; then 
          LAST_BACKUP="Today"
          BACKUP_STATUS="${SUCCESSC}"
          BACKUP_BTN="btn-success"
        elif [[ "${i}" == "1" ]]; then
          LAST_BACKUP="Yesterday" 
        else
          LAST_BACKUP="${i} days ago"
          if [[ "${i}" -lt "5" ]]; then
            BACKUP_STATUS="${SUCCESSC}"
          elif [[ "${i}" -gt "4" && "${i}" -lt "11" ]]; then
            BACKUP_STATUS="${WARNINGC}"
            BACKUP_BTN="btn-warning"
          else
            BACKUP_STATUS="${DANGERC}"
            BACKUP_BTN="btn-danger"
          fi
        fi
        BACKUP_MSG="Last backup: ${LAST_BACKUP} (${var}) in ${DB_BACKUP_PATH}"
        trace "${BACKUP_MSG}"
        return
      fi
    done
  fi
}

# Usage: get_commits [number of commits]
function get_commits() {
  git log -n $1 --pretty=format:"%n<table style=\"border-bottom: solid 1px rgba(127, 127, 127, 0.25);\" width=\"100%\" cellpadding=\"0\" cellspacing=\"0\"><tr><td width=\"90\" valign=\"top\" align=\"left\"><img src=\"{{GRAVATARURL}}/%an.png\" alt=\"%aN\" title=\"%aN\" width=\"64\" style=\"width: 64px; float: left; background-color: #f0f0f0; overflow: hidden; margin-top: 4px;\" class=\"img-circle\"></td><td valign=\"top\" style=\"padding-bottom: 20px;\"><strong>%ncommit <a style=\"color: {{PRIMARY}}; text-decoration: none; font-weight: bold;\" href=\"${REMOTEURL}/${APP}/%h.html\">%h</a>%nAuthor: %aN%nDate: %aD (%cr)%n%s</td></tr></table><br>" > "${statFile}"
  sed -i '/^commit/ s/$/ <\/strong><br>/' "${statFile}"
  sed -i '/^Author:/ s/$/ <br>/' "${statFile}"
  sed -i '/^Date:/ s/$/ <br><br>/' "${statFile}"
}

# Usage: url_check [source file]
function validate_urls() {
  grep -oP "(?<=href=\")[^\"]+(?=\")" $1 > "${trshFile}"
  while read URL; do
    CODE=$(curl -o /dev/null --silent --head --write-out '%{http_code}' "$URL")
    if [[ "${CODE}" != "200" ]]; then 
      sed -i "s,${URL},${REMOTEURL}/nolog.html,g" "${statFile}"
    fi
  done < "${trshFile}"
}

function assign_nav() {
  # Assign URLs - this will change later on
  ACTIVITY_NAV="activity.html"
  STATISTICS_NAV="stats.html"
  [[ -n "${PROFILEID}" ]] && ENGAGEMENT_NAV="engagement.html"
  [[ -n "${SCAN_MSG}" ]] && SCAN_NAV="scan.html"
  [[ -n "${FIREWALL_NAV}" ]] && FIREWALL_NAV="firewall.html"
  [[ -n "${BACKUP_STATUS}" ]] && BACKUP_NAV="backup.html"
}
