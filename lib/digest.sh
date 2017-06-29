#!/bin/bash
#
# digest.sh
#
###############################################################################
# Handles parsing and creating logs
###############################################################################
trace "Loading digest handling"

function createDigest() {
  message_state="DIGEST"
  htmlDir

  # Collect gravatars for all the authors in this repo
  for AUTHOR in $(git log --pretty=format:"%ae|%an" | sort | uniq); do
    AUTHOREMAIL=$(echo $AUTHOR | cut -d\| -f1 | tr -d '[[:space:]]' | tr '[:upper:]' '[:lower:]')
    AUTHORNAME=$(echo $AUTHOR | cut -d\| -f2)
    GRAVATAR="http://www.gravatar.com/avatar/$(echo -n $AUTHOREMAIL | md5sum)?d=404&s=200"
    IMGFILE="${LOCALHOSTPATH}/${APP}/avatar/$AUTHORNAME.png"
    # if [[ ! -f $IMGFILE ]]; then # If you wanna cache?
    curl -fso "${IMGFILE}" "${GRAVATAR}"
    # fi
  done

  # Attempt to get analytics
  analytics

  # Assemble the file
  DIGESTWRAP="$(<${deployPath}/html/${EMAILTEMPLATE}/digest/commit.html)"

  # If there have been no commits in the last week, skip creating the digest
  if [[ $(git log --since="7 days ago") ]]; then
    git log --pretty=format:"%n$DIGESTWRAP<strong>%ncommit <a style=\"color: {{PRIMARY}}; text-decoration: none; font-weight: bold;\" href=\"${REMOTEURL}/${APP}/%h.html\">%h</a>%nAuthor: %aN%nDate: %aD (%cr)%n%s</td></tr></table>" --since="7 days ago" > "${statFile}"
    sed -i '/^commit/ s/$/ <\/strong><br>/' "${statFile}"
    sed -i '/^Author:/ s/$/ <br>/' "${statFile}"
    sed -i '/^Date:/ s/$/ <br><br>/' "${statFile}"

    # Look for manual commits and strip their URLs 
    grep -oP "(?<=href=\")[^\"]+(?=\")" "${statFile}" > "${trshFile}"
    while read URL; do
      CODE=$(curl -o /dev/null --silent --head --write-out '%{http_code}' "$URL")
      echo "${CODE}"
      if [[ "${CODE}" != "200" ]]; then 
        echo "Trying to remove ${URL}"
        sed -i "s^${URL}^#^g" "${statFile}"
      fi
    done < "${trshFile}"

    cat "${deployPath}/html/${EMAILTEMPLATE}/digest/header.html" "${statFile}" "${deployPath}/html/${EMAILTEMPLATE}/digest/footer.html" > "${htmlFile}"

    # Randomize a positive Monday thought
    array[0]="Hope you had a good weekend!"
    array[1]="Alright Monday, let's do this."
    array[2]="Oh, hello Monday."
    array[3]="Welcome back, how was your weekend?"
    array[4]="Happy Monday and welcome back!"
    array[5]="Hello and good morning!"
    SIZE="${#array[@]}"
    RND="$(($RANDOM % $SIZE))"
    GREETING="${array[$RND]}"

    processHTML

    if [[ -z "${RESULT}" ]] || [[ "${RESULT}" == "0" ]] || [[ "${SIZE}" == "0" ]]; then
      sed -i '/ANALYTICS/d' "${htmlFile}"
    fi   

    # Get the email payload ready
    digestSendmail=$(<"${htmlFile}")
  else
    echo "No activity found, canceling digest."
    safeExit
  fi
}
