#!/usr/bin/env bash
#
# digest.sh
#
###############################################################################
# Handles parsing and creating logs
###############################################################################

# Initializa needed variables
var=(AUTHOR AUTHOREMAIL AUTHORNAME GRAVATAR IMGFILE DIGESTWRAP \
  DIGESTSLACK GREETING)
init_loop

function get_avatars() {
  for AUTHOR in $(git log --pretty=format:"%ae|%an" | sort | uniq); do
    AUTHOREMAIL=$(echo $AUTHOR | cut -d\| -f1 | tr -d '[[:space:]]' | tr '[:upper:]' '[:lower:]')
    AUTHORNAME=$(echo $AUTHOR | cut -d\| -f2)
    GRAVATAR="http://www.gravatar.com/avatar/$(echo -n $AUTHOREMAIL | md5sum)?d=404&s=200"

    # Check for missing Gravatar
    if "${curl_cmd}" --output /dev/null --silent --head --fail "${GRAVATAR}"; then
      dot
    else
      GRAVATAR="http://www.gravatar.com/avatar"
    fi

    if [[ "${SCPPOST}" != "TRUE" ]]; then 
      IMGFILE="${LOCALHOSTPATH}/${APP}/avatar/$AUTHORNAME.png"
    else
      #if [[ ! -d "/tmp/avatar" ]]; then
      #  umask 077 && mkdir /tmp/avatar &> /dev/null
      #fi
      IMGFILE="${avatar_dir}/${AUTHORNAME}.png"
    fi
    "${curl_cmd}" -fso "${IMGFILE}" "${GRAVATAR}"; dot
  done 
}

function create_digest() {
  if [[ -z "${DIGESTSLACK}" || "${DIGESTSLACK}" == "FALSE" ]] && [[ -z "${DIGESTEMAIL} " ]]; then 
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

    # Genereate the correct analytics chart
    ga_over_time "${METRIC}" 7; dot

    # If we're displaying details, get them now
    if [[ "${INCLUDE_DETAILS}" == "TRUE" ]]; then
      ga_data_loop
    fi
    
    # Assemble the file
    DIGESTWRAP="$(<${stir_path}/html/${HTMLTEMPLATE}/digest/commit.html)"

    # If there have been no commits in the last week, skip creating the digest
    if [[ $(git log --since="7 days ago") ]]; then
      git log --pretty=format:"%n$DIGESTWRAP<strong>%ncommit <a style=\"color: {{PRIMARY}}; text-decoration: none; font-weight: bold;\" href=\"${REMOTEURL}/${APP}/%h.html\">%h</a>%nAuthor: %aN%nDate: %aD (%cr)%n%s</td></tr></table>" --since="7 days ago" > "${stat_file}"; dot
      sed -i '/^commit/ s/$/ <\/strong><br>/' "${stat_file}"
      sed -i '/^Author:/ s/$/ <br>/' "${stat_file}"
      sed -i '/^Date:/ s/$/ <br><br>/' "${stat_file}"

      # Look for manual commits and strip their URLs 
      grep -oP "(?<=href=\")[^\"]+(?=\")" "${stat_file}" > "${trash_file}"; dot
      while read URL; do
        CODE=$(${curl_cmd} -o /dev/null --silent --head --write-out '%{http_code}' "$URL")
        if [[ "${CODE}" != "200" ]]; then 
          # sed -i "s,${URL},${REMOTEURL}/nolog.html,g" "${stat_file}"
          sed -i "s,${URL},${REPOHOST}/${REPO},g" "${stat_file}"; dot
        fi
      done < "${trash_file}"

      cat "${stir_path}/html/${HTMLTEMPLATE}/digest/header.html" "${stat_file}" "${stir_path}/html/${HTMLTEMPLATE}/digest/footer.html" > "${html_file}"; dot

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

      # Get the email payload ready
      digestSendmail=$(<"${html_file}")
    else
      console "No activity found, canceling digest."
      clean_exit
    fi
  fi
}
