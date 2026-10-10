#!/usr/bin/env bash
#
# stats.sh
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


# Generate a repository chart, reusing cached output when possible.
# Usage: build_stats_chart [chart name]
build_stats_chart() {
  local chart_name="${1}"
  local repo_dir="${WORK_PATH}/${APP}"
  local output_file="${stat_dir}/${chart_name}.svg"
  local cache_dir="${HOME}/.cache/stir/stats/charts"
  local repo_head cache_key cache_file temp_file

  # Identify the current repository state.
  repo_head="$(cd "${repo_dir}" && git rev-parse HEAD 2>/dev/null)" || return 1

  # Key includes the repository, commit, chart, and appearance.
  cache_key="$(
    printf '%s\n' \
      "v1" "${repo_dir}" "${repo_head}" \
      "${chart_name}" "${CHART_COLOR}" \
      "Roboto, Helvetica, Arial, sans-serif" |
      git hash-object --stdin
  )" || return 1

  cache_file="${cache_dir}/${cache_key}.svg"

  # Reuse an existing chart.
  if [[ -s "${cache_file}" ]]; then
    if cp "${cache_file}" "${output_file}"; then
      trace "Chart cache hit: ${chart_name}"
      return 0
    fi
  fi

  trace "Chart cache miss: ${chart_name}"

  # Generate into a temporary file for safe cache writes.
  temp_file=""

  if mkdir -p "${cache_dir}" 2>/dev/null; then
    temp_file="$(mktemp --suffix=.svg \
      "${cache_dir}/.${chart_name}.XXXXXXXX")" || temp_file=""
  fi

  # Fall back to direct generation if cache isn't writable.
  if [[ -z "${temp_file}" ]]; then
    temp_file="${output_file}"
  fi

  if ! "${gitchart_cmd}" -r "${repo_dir}" \
    "${chart_name}" "${temp_file}" &>/dev/null; then
    [[ "${temp_file}" != "${output_file}" ]] && rm -f "${temp_file}"
    return 1
  fi

  if [[ ! -s "${temp_file}" ]]; then
    [[ "${temp_file}" != "${output_file}" ]] && rm -f "${temp_file}"
    return 1
  fi

  # Apply Stir's chart appearance.
  sed -i "s/#4444ff/${CHART_COLOR}/g" "${temp_file}"
  sed -i \
    's/Consolas, "Liberation Mono", Menlo, Courier, monospace/Roboto, Helvetica, Arial, sans-serif/g' \
    "${temp_file}"

  # Publish and cache the completed SVG.
  if [[ "${temp_file}" != "${output_file}" ]]; then
    if mv -f "${temp_file}" "${cache_file}"; then
      cp "${cache_file}" "${output_file}" || return 1
    else
      cp "${temp_file}" "${output_file}" || return 1
      rm -f "${temp_file}"
    fi
  fi

  return 0
}

build_stats() {
  #hash gitchart 2>/dev/null || {
  #error "Can not chart project stats, gitchart not installed." 
  #}

  if [[ -z "${gitchart_cmd}" ]]; then
    PROJSTATS=""
    warning "Can not chart project statistics, gitchart not installed."
    quiet_exit
  fi
  
  if [[ "${REMOTE_LOG}" == "TRUE" ]]; then
    # Setup up tmp work folder
    #if [[ ! -d "${stat_dir}" ]]; then
    #  umask 077 && mkdir "${stat_dir}" &> /dev/null
    #fi

    # Prep assets
    cp -R "${stir_path}/html/${HTML_TEMPLATE}/stats/css" "${stat_dir}/"
    cp -R "${stir_path}/html/${HTML_TEMPLATE}/stats/fonts" "${stat_dir}/"
    cp -R "${stir_path}/html/${HTML_TEMPLATE}/stats/js" "${stat_dir}/"

    echo -n "Generating files"

    # Define dashboard navigation
    assign_nav

    # Collect gravatars for all the authors in this repo
    prepare_author_avatars

    # Start building the main stat overview dashboard
    # Attempt to get analytics
    ga4_summary

    # Code stats
    CODE_STATS=$(git log --author="${full_user}" --pretty=tformat: --numstat | \
      awk '{ add += $1 ; subs += $2 ; loc += $1 - $2 } END { printf \
      "Total lines of code: %s<br>(+%s added | -%s deleted)\n",loc,add,subs }' -)
   
    # Get commits
    get_commits 6

    # Process the HTML
    cat "${stir_path}/html/${HTML_TEMPLATE}/stats/index.html" > "${html_file}"
    render_html

    cat "${html_file}" > "${stat_dir}/index.html"

    # Create SVG charts, using cached versions when available.
    repo_charts=(authors commits_day_week commits_hour_day commits_hour_week \
      commits_month commits_year commits_year_month files_type)

    for i in "${repo_charts[@]}"; do
      if ! build_stats_chart "${i}"; then
        warning "Could not generate chart: ${i}"
      fi
    done

    # Create SVG charts
    #repo_charts=(authors commits_day_week commits_hour_day commits_hour_week \
    #  commits_month commits_year commits_year_month files_type)

    #  for i in "${repo_charts[@]}" ; do
    #    "${gitchart_cmd}" -r "${WORK_PATH}/${APP}" "${i}" \
    #      "${stat_dir}/${i}.svg" &>> /dev/null

     #   sed -i "s/#4444ff/${CHART_COLOR}/g" "${stat_dir}/${i}.svg"
     #   sed -i \
     #     's/Consolas, "Liberation Mono", Menlo, Courier, monospace/Roboto, Helvetica, Arial, sans-serif/g' \
     #     "${stat_dir}/${i}.svg"
    #  done
   
    # Create sub pages
    trace "START activity"
    build_stats_activity
    trace "END activity"

    trace "START code"
    build_stats_code
    trace "END code"

    trace "START firewall"
    build_stats_firewall
    trace "END firewall"

    trace "START backup"
    build_stats_backup
    trace "END backup"

    trace "START engagement"
    build_stats_engagement
    trace "END engagement"

    trace "START CSS"
    build_stats_css
    trace "END CSS"

    # Post files
    trace "START publish"
    publish_html
    trace "END publish"
  fi
}

build_stats_activity() {
  trace "START counting commits"
  TOTAL_COMMITS="$(git rev-list --count "${MASTER}")"
  trace "END counting commits"

  trace "START generating commit HTML"
  get_commits "${TOTAL_COMMITS}"
  trace "END generating commit HTML"

  #trace "START validating URLs"
  #validate_urls "${stat_file}"
  #trace "END validating URLs"

  trace "START rendering activity HTML"
  cat "${stir_path}/html/${HTML_TEMPLATE}/stats/activity.html" > "${html_file}"
  render_html
  cat "${html_file}" > "${stat_dir}/activity.html"
  trace "END rendering activity HTML"
}

build_stats_code() {
  # Process the HTML
  cat "${stir_path}/html/${HTML_TEMPLATE}/stats/stats.html" > "${html_file}"
  render_html; cat "${html_file}" > "${stat_dir}/stats.html"
}

# This is a special snowflake for now, called from within scan_host()
build_stats_scan() {
  
  #if [[ ! -d "${stat_dir}" ]]; then
  #  umask 077 && mkdir ${stat_dir} &> /dev/null
  #fi

  # Text mode, Nikto is broked :(
  SCAN_STATS=$(<${scan_file})
  cat "${stir_path}/html/${HTML_TEMPLATE}/stats/scan.txt.html" > "${html_file}"
  render_html; cat "${html_file}" > "${stat_dir}/scan.html"

  # Assuming HTML output from Nikto was working, we'd run this
  # SCAN_STATS=$(<${scan_html})
  # cat "${stir_path}/html/${HTML_TEMPLATE}/stats/scan.html" > "${html_file}"
  # render_html; cat "${html_file}" > "${stat_dir}/scan.html"
}

build_stats_firewall() {
  # Process the HTML
  cat "${stir_path}/html/${HTML_TEMPLATE}/stats/firewall.html" > "${html_file}"
  render_html; cat "${html_file}" > "${stat_dir}/firewall.html"
}

build_stats_engagement() {
  if [[ -z "${PROFILE_ID}" ]]; then
    trace "Google Analytics not configured"
    return
  fi

  cat "${stir_path}/html/${HTML_TEMPLATE}/stats/engagement.html" > "${html_file}"

  # How many days of analytics to display?
  if [[ -z "${ENGAGEMENT_DAYS}" ]]; then
    ENGAGEMENT_DAYS="7"
  fi

  ga_var=(pageviews users newUsers sessions organicSearches)

  for i in "${ga_var[@]}"; do
    ga4_over_time "${i}" "${ENGAGEMENT_DAYS}"
  done

  # Process the HTML
  render_html
  cat "${html_file}" > "${stat_dir}/engagement.html"
}

build_stats_css() {
  # Process the CSS files
  cat "${stir_path}/html/${HTML_TEMPLATE}/stats/css/${THEME_MODE}.css" > "${html_file}"
  render_html; cat "${html_file}" > "${stat_dir}/css/${THEME_MODE}.css"
}

build_stats_backup() {
  # Get file directory
  #echo "${BACKUP_FILES}" > "${trash_file}"

  echo "${BACKUP_FILES}" | grep -Po '"path_display":.*?[^\\]",' > "${trash_file}"
  sed -i 's/\"path_display\": \"//g' "${trash_file}"
  sed -i 's/\",//g' "${trash_file}"
  sed -i 's/$/<hr>/' "${trash_file}"
  BACKUP_FILES=$(tac ${trash_file})
  echo "${BACKUP_FILES}" > "${trash_file}"

  # Process the HTML
  cat "${stir_path}/html/${HTML_TEMPLATE}/stats/backup.html" > "${html_file}"
  render_html; cat "${html_file}" > "${stat_dir}/backup.html"
}

test_backup() {
  # Are we setup?
  if [[ -z "${DB_BACKUP_PATH}" ]] || [[ -z "${DB_API_TOKEN}" ]]; then
    return
  else 
    # Examine the Dropbox backup directory
    "${curl_cmd}" -s -X POST https://api.dropboxapi.com/2/files/list_folder \
    --header "Authorization: Bearer ${DB_API_TOKEN}" \
    --header "Content-Type: application/json" \
    --data "{\"path\": \"${DB_BACKUP_PATH}\",\"recursive\": false,
      \"include_media_info\": false,\"include_deleted\": false,
      \"include_has_explicit_shared_members\": false}" > "${trash_file}"

    # Check for what we might assume is error output
    if [[ $(grep -a "error" "${trash_file}") ]]; then
      warning "Error in backup configuration"
      return
    fi

    # Store file list for later
    BACKUP_FILES="$(<${trash_file})" 

    # Start the loop
    for i in $(seq 0 365)
      do 
      var="$(date -d "${i} day ago" +"%Y-%m-%d")"
      if [[ $(grep -a "${var}" "${trash_file}") ]]; then
        # Assume success
        BACKUP_STATUS="${SUCCESS_COLOR}"
        BACKUP_BTN="btn-success"
        if [[ "${i}" == "0" ]]; then 
          LAST_BACKUP="Today"
          BACKUP_STATUS="${SUCCESS_COLOR}"
          BACKUP_BTN="btn-success"
        elif [[ "${i}" == "1" ]]; then
          LAST_BACKUP="Yesterday" 
        else
          LAST_BACKUP="${i} days ago"
          if [[ "${i}" -lt "5" ]]; then
            BACKUP_STATUS="${SUCCESS_COLOR}"
          elif [[ "${i}" -gt "4" && "${i}" -lt "11" ]]; then
            BACKUP_STATUS="${WARNING_COLOR}"
            BACKUP_BTN="btn-warning"
          else
            BACKUP_STATUS="${DANGER_COLOR}"
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
get_commits() {
  local count="${1:-6}"
  local commit_url=""
  local commit_link

  if commit_url="$(git_get_commit_url)"; then
    commit_link="<a style=\"color: {{PRIMARY}}; text-decoration: none; font-weight: bold;\" href=\"${commit_url}%H\">%h</a>"
  else
    # Unsupported or missing Git remote.
    commit_link="%h"
  fi

  git log -n "${count}" --pretty=format:"%n<table style=\"border-bottom: solid 1px rgba(127, 127, 127, 0.25);\" width=\"100%\" cellpadding=\"0\" cellspacing=\"0\"><tr><td width=\"90\" valign=\"top\" align=\"left\"><img src=\"{{GRAVATARURL}}/%an.png\" alt=\"%aN\" title=\"%aN\" width=\"64\" style=\"width: 64px; float: left; background-color: #f0f0f0; overflow: hidden; margin-top: 4px;\" class=\"img-circle\"></td><td valign=\"top\" style=\"padding-bottom: 20px;\"><strong>%ncommit ${commit_link}%nAuthor: %aN%nDate: %aD (%cr)%n%s</td></tr></table><br>" > "${stat_file}"

  sed -i '/^commit/ s/$/ <\/strong><br>/' "${stat_file}"
  sed -i '/^Author:/ s/$/ <br>/' "${stat_file}"
  sed -i '/^Date:/ s/$/ <br><br>/' "${stat_file}"
}

assign_nav() {
  # Assign URLs - this will change later on
  ACTIVITY_NAV="activity.html"
  STATISTICS_NAV="stats.html"
  [[ -n "${PROFILE_ID}" ]] && ENGAGEMENT_NAV="engagement.html"
  [[ -n "${SCAN_MSG}" ]] && SCAN_NAV="scan.html"
  [[ -n "${FIREWALL_NAV}" ]] && FIREWALL_NAV="firewall.html"
  [[ -n "${BACKUP_STATUS}" ]] && BACKUP_NAV="backup.html"
}
