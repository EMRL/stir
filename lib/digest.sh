#!/bin/bash
#
# digest.sh
#
# Handles parsing and creating logs
trace "Loading log handling"

function createDigest() {
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
        git log --pretty=format:"%n$DIGESTWRAP<strong>%ncommit <a style=\"color: #47ACDF; text-decoration: none; font-weight: bold;\" href=\"${REMOTEURL}/${APP}/%h.html\">%h</a>%nAuthor: %aN%nDate: %aD (%cr)%n%s</td></tr></table>" --since="7 days ago" > "${statFile}"
        sed -i '/^commit/ s/$/ <\/strong><br>/' "${statFile}"
        sed -i '/^Author:/ s/$/ <br>/' "${statFile}"
        sed -i '/^Date:/ s/$/ <br><br>/' "${statFile}"
        cat "${deployPath}/html/${EMAILTEMPLATE}/digest/header.html" "${statFile}" "${deployPath}/html/${EMAILTEMPLATE}/digest/footer.html" > "${trshFile}"

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

        # Process and replace variables
        sed -e "s^{{WEEKOF}}^${WEEKOF}^g" \
            -e "s^{{NOW}}^${NOW}^g" \
            -e "s^{{PROJCLIENT}}^${PROJCLIENT}^g" \
            -e "s^{{GRAVATARURL}}^${REMOTEURL}\/${APP}\/avatar^g" \
            -e "s^{{DIGESTWRAP}}^${DIGESTWRAP}^g" \
            -e "s^{{PROJCLIENT}}^${PROJCLIENT}^g" \
            -e "s^{{CLIENTLOGO}}^${CLIENTLOGO}^g" \
            -e "s^{{PRODURL}}^${PRODURL}^g" \
            -e "s^{{GREETING}}^${GREETING}^g" \
            -e "s^{{REMOTEURL}}^${REMOTEURL}^g" \
            -e "s^{{ANALYTICSMSG}}^${ANALYTICSMSG}^g" \
            -e "s^{{STATURL}}^${REMOTEURL}\/${APP}\/stats^g" \
            "${trshFile}" > "${statFile}"

        if [[ -z "${RESULT}" ]] || [[ "${RESULT}" == "0" ]] || [[ "${SIZE}" == "0" ]]; then
            sed -i '/ANALYTICS/d' "${statFile}"
        fi   

        if [[ -z "${CLIENTLOGO}" ]]; then
            sed -i '/CLIENTLOGO/d' "${statFile}"
        fi   

        # Get the email payload ready
        digestSendmail=$(<"${statFile}")
    else
        echo "No activity found, canceling digest."
        safeExit
    fi
}
