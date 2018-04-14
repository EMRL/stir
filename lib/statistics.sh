#!/usr/bin/env bash
#
# statistics.sh
#
###############################################################################
# Generate HTML statistics pages
###############################################################################
trace "Loading statistics functions"

# Initialize variables
read -r DB_API_TOKEN DB_BACKUP_PATH LAST_BACKUP BACKUP_STATUS <<< ""
echo "${DB_API_TOKEN} ${DB_BACKUP_PATH} ${LAST_BACKUP} 
  ${BACKUP_STATUS}" > /dev/null

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

    # Start the loop
    for i in $(seq 0 365)
      do 
      var="$(date -d "${i} day ago" +"%Y-%m-%d")"
      if [[ $(grep "${var}" "${trshFile}") ]]; then
        if [[ "${i}" == "0" ]]; then 
          LAST_BACKUP="Today"
          BACKUP_STATUS="${SUCCESSC}"
        elif [[ "${i}" == "1" ]]; then
          LAST_BACKUP="Yesterday" 
          BACKUP_STATUS="${SUCCESSC}"
        else
          LAST_BACKUP="${i} days ago"
          if [[ "${i}" < "5" ]]; then
            BACKUP_STATUS="${SUCCESSC}"
          elif [[ "${i}" > "4" && "${i}" < "11" ]]; then
            BACKUP_STATUS="${WARNINGC}"
          else
            BACKUP_STATUS="${DANGERC}"
          fi
 
        fi
        trace "Last backup: ${LAST_BACKUP} (${var}) in ${DB_BACKUP_PATH}"
        return
      fi
    done
  fi
}
