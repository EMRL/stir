#!/bin/bash
#
# statistics.sh
#
###############################################################################
# Generate HTML statistics pages
###############################################################################
trace "Loading statistics functions"

function projStats() {
  hash gitchart 2>/dev/null || {
  error "gitchart not installed." 
  }
  if [[ "${REMOTELOG}" == "TRUE" ]] && [[ "${LOCALHOSTPOST}" == "TRUE" ]]; then
    [[ ! -d "${LOCALHOSTPATH}/${APP}" ]] && mkdir "${LOCALHOSTPATH}/${APP}"
    [[ ! -d "${LOCALHOSTPATH}/${APP}/stats" ]] && mkdir "${LOCALHOSTPATH}/${APP}/stats"
    notice "Generating files..."

    # Process the HTML
    cat "${deployPath}/html/${HTMLTEMPLATE}/stats/index.html" > "${htmlFile}"
    processHTML
    cat "${htmlFile}" > "${LOCALHOSTPATH}/${APP}/stats/index.html"

    # Create the charts
    /usr/bin/gitchart -r "${WORKPATH}/${APP}" authors "${LOCALHOSTPATH}/${APP}/stats/authors.svg" &>> /dev/null &
    /usr/bin/gitchart -t "" -r "${WORKPATH}/${APP}" commits_day_week "${LOCALHOSTPATH}/${APP}/stats/commits_day_week.svg" &>> /dev/null &
    /usr/bin/gitchart -t "" -r "${WORKPATH}/${APP}" commits_hour_day "${LOCALHOSTPATH}/${APP}/stats/commits_hour_day.svg" &>> /dev/null &
    /usr/bin/gitchart -t "" -r "${WORKPATH}/${APP}" commits_hour_week "${LOCALHOSTPATH}/${APP}/stats/commits_hour_week.svg" &>> /dev/null &
    /usr/bin/gitchart -t "" -r "${WORKPATH}/${APP}" commits_month "${LOCALHOSTPATH}/${APP}/stats/commits_month.svg" &>> /dev/null &
    /usr/bin/gitchart -t "" -r "${WORKPATH}/${APP}" commits_year "${LOCALHOSTPATH}/${APP}/stats/commits_year.svg" &>> /dev/null &
    /usr/bin/gitchart -t "" -r "${WORKPATH}/${APP}" commits_year_month "${LOCALHOSTPATH}/${APP}/stats/commits_year_month.svg" &>> /dev/null &
    /usr/bin/gitchart -t "" -r "${WORKPATH}/${APP}" files_type "${LOCALHOSTPATH}/${APP}/stats/files_type.svg" &>> /dev/null &
    # /usr/bin/gitchart -r "${WORKPATH}/${APP}" commits_day "${LOCALHOSTPATH}/${APP}/stats/commits_day.svg" &>> /dev/null &
    spinner $!

    # Process primary chart color and set permissions if needed
    sleep 1; find "${LOCALHOSTPATH}/${APP}/stats/" -type f -exec sed -i "s/#9999ff/${PRIMARYC}/g" {} \;
    chmod -R a+rw "${deployPath}/html/${HTMLTEMPLATE}/stats" &> /dev/null
  fi
}
