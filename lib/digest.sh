#!/usr/bin/env bash
#
# digest.sh
#
###############################################################################
# Handles parsing and creating logs
###############################################################################

# Initializa needed variables
var=(AUTHOR AUTHOREMAIL AUTHORNAME GRAVATAR IMGFILE DIGESTWRAP \
  DIGEST_SLACK GREETING NO_ACTIVITY)
init_loop

function get_avatars() {
  if [[ "${SKIP_GIT}" == "1" ]]; then
    return
  fi
  
  for AUTHOR in $(git log --pretty=format:"%ae|%an" | sort | uniq); do
    AUTHOREMAIL=$(echo $AUTHOR | cut -d\| -f1 | tr -d '[[:space:]]' | tr '[:upper:]' '[:lower:]')
    AUTHORNAME=$(echo $AUTHOR | cut -d\| -f2)
    GRAVATAR="https://gravatar.com/avatar/$(echo -n ${AUTHOREMAIL} | md5sum - | cut -d' ' -f1)?s=300"

    # Check for missing Gravatar
    if "${curl_cmd}" --output /dev/null --silent --head --fail "${GRAVATAR}"; then
      dot
    else
      GRAVATAR="https://www.gravatar.com/avatar"
    fi

    if [[ "${SCP_POST}" != "TRUE" ]]; then 
      IMGFILE="${LOCAL_HOST_PATH}/${APP}/avatar/$AUTHORNAME.png"
    else
      #if [[ ! -d "/tmp/avatar" ]]; then
      #  umask 077 && mkdir /tmp/avatar &> /dev/null
      #fi
      IMGFILE="${avatar_dir}/${AUTHORNAME}.png"
    fi
    "${curl_cmd}" -fso "${IMGFILE}" "${GRAVATAR}"; dot
  done 
}

function get_digest_commits() {
  if [[ "${SKIP_GIT}" == "1" ]]; then
    return
  fi

  # Get ready
  DIGESTWRAP="$(<${stir_path}/html/${HTML_TEMPLATE}/digest/commit.html)"
  > "${stat_file}"

  # If there have been no commits in the last week, skip
  if [[ $(git log --since="7 days ago") ]]; then
    git log --pretty=format:"%n$DIGESTWRAP<strong>%ncommit <a style=\"color: {{PRIMARY}}; text-decoration: none; font-weight: bold;\" href=\"${REMOTE_URL}/${APP}/%h.html\">%h</a>%nAuthor: %aN%nDate: %aD (%cr)%n%s</td></tr></table>" --since="7 days ago" > "${stat_file}"; dot
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

function check_stats() {
  trace "Future site of stats check"
}

function create_digest() {
  if [[ -z "${DIGEST_SLACK}" || "${DIGEST_SLACK}" == "FALSE" ]] && [[ -z "${DIGEST_EMAIL} " ]]; then 
    return
  else
    message_state="DIGEST"
    html_dir
    
    # Collect gravatars for all the authors in this repo
    get_avatars; dot

    # If configured, setup RSS news
    create_rss_payload; dot
    
    # Attempt to get analytics
    analytics; dot

    # Generate the correct analytics chart
    ga_over_time "${METRIC}" 7; dot

    # If we're displaying details, get them now
    if [[ "${INCLUDE_DETAILS}" == "TRUE" ]]; then
      ga_data_loop
    fi

    # Email marketing stats
    if [[ -n "${MAUTIC_URL}" && -n "${MAUTIC_AUTH}" ]]; then
      mtc_data_loop; dot
    fi

    get_digest_commits

    # If there's no analytics and no commit activity, there's no need for a digest
    if [[ -z "${ANALYTICSMSG}" ]] && [[ "${NO_ACTIVITY}" == "1" ]]; then
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

    process_html; dot

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
