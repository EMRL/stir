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
      echo -n "."
    else
      GRAVATAR="http://www.gravatar.com/avatar"
    fi

    if [[ "${SCPPOST}" != "TRUE" ]]; then 
      IMGFILE="${LOCALHOSTPATH}/${APP}/avatar/$AUTHORNAME.png"
    else
      #if [[ ! -d "/tmp/avatar" ]]; then
      #  umask 077 && mkdir /tmp/avatar &> /dev/null
      #fi
      IMGFILE="${avatarDir}/${AUTHORNAME}.png"
    fi
    "${curl_cmd}" -fso "${IMGFILE}" "${GRAVATAR}"
  done  
}

function create_digest() {
  if [[ -z "${DIGESTSLACK}" || "${DIGESTSLACK}" == "FALSE" ]] && [[ -z "${DIGESTEMAIL} " ]]; then 
    return
  else
    message_state="DIGEST"
    htmlDir
    
    # Collect gravatars for all the authors in this repo
    get_avatars

    # If configured, setup RSS news
    create_rss_payload
    
    # Attempt to get analytics
    analytics

    # Genereate the correct analytics chart
    ga_over_time "${METRIC}" 7

    # Assemble the file
    DIGESTWRAP="$(<${deployPath}/html/${HTMLTEMPLATE}/digest/commit.html)"

    # If there have been no commits in the last week, skip creating the digest
    if [[ $(git log --since="7 days ago") ]]; then
      git log --pretty=format:"%n$DIGESTWRAP<strong>%ncommit <a style=\"color: {{PRIMARY}}; text-decoration: none; font-weight: bold;\" href=\"${REMOTEURL}/${APP}/%h.html\">%h</a>%nAuthor: %aN%nDate: %aD (%cr)%n%s</td></tr></table>" --since="7 days ago" > "${statFile}"
      sed -i '/^commit/ s/$/ <\/strong><br>/' "${statFile}"
      sed -i '/^Author:/ s/$/ <br>/' "${statFile}"
      sed -i '/^Date:/ s/$/ <br><br>/' "${statFile}"

      # Look for manual commits and strip their URLs 
      grep -oP "(?<=href=\")[^\"]+(?=\")" "${statFile}" > "${trshFile}"
      while read URL; do
        CODE=$(${curl_cmd} -o /dev/null --silent --head --write-out '%{http_code}' "$URL")
        if [[ "${CODE}" != "200" ]]; then 
          # sed -i "s,${URL},${REMOTEURL}/nolog.html,g" "${statFile}"
          sed -i "s,${URL},${REPOHOST}/${REPO},g" "${statFile}"
        fi
      done < "${trshFile}"

      cat "${deployPath}/html/${HTMLTEMPLATE}/digest/header.html" "${statFile}" "${deployPath}/html/${HTMLTEMPLATE}/digest/footer.html" > "${htmlFile}"

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

      # Git some stats
      # git log --no-merges  --since="7 days ago" --reverse --stat | grep -Eo "[0-9]{1,} files? changed" | grep -Eo "[0-9]{1,}" | awk "{ sum += \$1 } END { print sum }"
      process_html

      # Strip out useless analytics results
      if [[ -z "${RESULT}" ]] || [[ "${RESULT}" == "0" ]] || [[ "${SIZE}" == "0" ]]; then
        sed -i '/ANALYTICS/d' "${htmlFile}"
      # else
        if [[ "${METRIC}" == "hits" ]] && [[ "${RESULT}" -lt "499" ]]; then
          sed -i '/ANALYTICS/d' "${htmlFile}"
        fi
      fi   

      # Get the email payload ready
      digestSendmail=$(<"${htmlFile}")
    else
      console "No activity found, canceling digest."
      safeExit
    fi
  fi
}
