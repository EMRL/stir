#!/usr/bin/env bash
#
# statistics.sh
#
###############################################################################
# Generate HTML statistics pages
###############################################################################
trace "Loading statistics functions"

function project_stats() {
  hash gitchart 2>/dev/null || {
  error "gitchart not installed." 
  }
  if [[ "${REMOTELOG}" == "TRUE" ]]; then
    # Check for approval queue
    queue_check

    # Setup up tmp work folder
    if [[ ! -d "/tmp/stats" ]]; then
      umask 077 && mkdir /tmp/stats &> /dev/null
    fi

    notice "Generating files..."

    # Attempt to get analytics
    analytics
    
    # Process the HTML
    cat "${deployPath}/html/${HTMLTEMPLATE}/stats/index.html" > "${htmlFile}"
    process_html
    cat "${htmlFile}" > "/tmp/stats/index.html"

    # Create the charts
    /usr/bin/gitchart -r "${WORKPATH}/${APP}" authors "/tmp/stats/authors.svg" &>> /dev/null &
    /usr/bin/gitchart -t "" -r "${WORKPATH}/${APP}" commits_day_week "/tmp/stats/commits_day_week.svg" &>> /dev/null &
    /usr/bin/gitchart -t "" -r "${WORKPATH}/${APP}" commits_hour_day "/tmp/stats/commits_hour_day.svg" &>> /dev/null &
    /usr/bin/gitchart -t "" -r "${WORKPATH}/${APP}" commits_hour_week "/tmp/stats/commits_hour_week.svg" &>> /dev/null &
    /usr/bin/gitchart -t "" -r "${WORKPATH}/${APP}" commits_month "/tmp/stats/commits_month.svg" &>> /dev/null &
    /usr/bin/gitchart -t "" -r "${WORKPATH}/${APP}" commits_year "/tmp/stats/commits_year.svg" &>> /dev/null &
    /usr/bin/gitchart -t "" -r "${WORKPATH}/${APP}" commits_year_month "/tmp/stats/commits_year_month.svg" &>> /dev/null &
    /usr/bin/gitchart -t "" -r "${WORKPATH}/${APP}" files_type "/tmp/stats/files_type.svg" &>> /dev/null &
    spinner $!

    # Process primary chart color and set permissions if needed
    sleep 1; find "/tmp/stats/" -type f -exec sed -i "s/#9999ff/${PRIMARYC}/g" {} \;

    postLog
#   if [[ "${LOCALHOSTPOST}" == "TRUE" ]]; then
#     [[ ! -d "${LOCALHOSTPATH}/${APP}" ]] && mkdir "${LOCALHOSTPATH}/${APP}"
#     [[ ! -d "${LOCALHOSTPATH}/${APP}/stats" ]] && mkdir "${LOCALHOSTPATH}/${APP}/stats"
#     cp -R "/tmp/stats" "${LOCALHOSTPATH}/${APP}"
#     chmod -R a+rw "${deployPath}/html/${HTMLTEMPLATE}/stats" &> /dev/null
#   fi
  fi
}
