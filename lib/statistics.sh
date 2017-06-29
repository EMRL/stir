#!/bin/bash
#
# git.sh
#
# Handles git related processes
trace "Loading statistics functions"

function projStats() {
    hash gitchart 2>/dev/null || {
    error "gitchart not installed." 
    }
    if [[ "${REMOTELOG}" == "TRUE" ]] && [[ "${LOCALHOSTPOST}" == "TRUE" ]]; then
        if [[ ! -d "${LOCALHOSTPATH}/${APP}" ]]; then
            mkdir "${LOCALHOSTPATH}/${APP}"
        fi
        if [[ ! -d "${LOCALHOSTPATH}/${APP}/stats" ]]; then
            mkdir "${LOCALHOSTPATH}/${APP}/stats"
        fi
        notice "Generating files..."

        # Process the HTML
        cat "${deployPath}/html/${EMAILTEMPLATE}/stats/index.html" > "${htmlFile}"

        # Clean this up later
        #sed -i -e "s^{{NOW}}^${NOW}^g" \
        #    -e "s^{{PROJNAME}}^${PROJNAME}^g" \
        #    -e "s^{{CLIENTLOGO}}^${CLIENTLOGO}^g" \
        #    -e "s^{{DEVURL}}^${DEVURL}^g" \
        #    -e "s^{{PRODURL}}^${PRODURL}^g" \
        #    -e "s^{{DEFAULT}}^${DEFAULTC}^g" \
        #    -e "s^{{PRIMARY}}^${PRIMARYC}^g" \
        #    "${htmlFile}" # > "${LOCALHOSTPATH}/${APP}/stats/index.html"

        processHTML
        cat "${htmlFile}" > "${LOCALHOSTPATH}/${APP}/stats/index.html"

        # Create the charts
        /usr/bin/gitchart -r "${WORKPATH}/${APP}" authors "${LOCALHOSTPATH}/${APP}/stats/authors.svg" &>> /dev/null &
        # /usr/bin/gitchart -r "${WORKPATH}/${APP}" commits_day "${LOCALHOSTPATH}/${APP}/stats/commits_day.svg" &>> /dev/null &
        /usr/bin/gitchart -t "" -r "${WORKPATH}/${APP}" commits_day_week "${LOCALHOSTPATH}/${APP}/stats/commits_day_week.svg" &>> /dev/null &
        /usr/bin/gitchart -t "" -r "${WORKPATH}/${APP}" commits_hour_day "${LOCALHOSTPATH}/${APP}/stats/commits_hour_day.svg" &>> /dev/null &
        /usr/bin/gitchart -t "" -r "${WORKPATH}/${APP}" commits_hour_week "${LOCALHOSTPATH}/${APP}/stats/commits_hour_week.svg" &>> /dev/null &
        /usr/bin/gitchart -t "" -r "${WORKPATH}/${APP}" commits_month "${LOCALHOSTPATH}/${APP}/stats/commits_month.svg" &>> /dev/null &
        /usr/bin/gitchart -t "" -r "${WORKPATH}/${APP}" commits_year "${LOCALHOSTPATH}/${APP}/stats/commits_year.svg" &>> /dev/null &
        /usr/bin/gitchart -t "" -r "${WORKPATH}/${APP}" commits_year_month "${LOCALHOSTPATH}/${APP}/stats/commits_year_month.svg" &>> /dev/null &
        /usr/bin/gitchart -t "" -r "${WORKPATH}/${APP}" files_type "${LOCALHOSTPATH}/${APP}/stats/files_type.svg" &>> /dev/null &
        spinner $!

        # Process primary chart color and setpermissions if needed
        sleep 1; find "${LOCALHOSTPATH}/${APP}/stats/" -type f -exec sed -i "s/#9999ff/${PRIMARYC}/g" {} \;
        chmod -R a+rw "${deployPath}/html/${EMAILTEMPLATE}/stats" &> /dev/null
    fi
}
