#!/bin/bash
#
# process-html.sh
#
###############################################################################
# Filters through html templates to inject our project's variables
###############################################################################
trace "Loading html handling"

function processHTML() {
    # Clean out the variables stuff we don't need
    [[ -z "${DEVURL}" ]] && sed -i '/<strong>Staging URL:/d' "${htmlFile}"
    [[ -z "${PRODURL}" ]] && sed -i '/PRODURL/d' "${htmlFile}"
    [[ -z "${PROJCLIENT}" ]] && sed -i 's/()//' "${htmlFile}"
    [[ -z "${CLIENTLOGO}" ]] && sed -i '/CLIENTLOGO/d' "${htmlFile}"
    [[ -z "${RESULT}" ]] || [[ "${RESULT}" == "0" ]] || [[ "${SIZE}" == "0" ]] && sed -i '/ANALYTICS/d' "${htmlFile}"
    [[ -z "${SMOOCHID}" ]] && sed -i '/SMOOCHID/d' "${htmlFile}"

    # Get to work
    sed -i -e "s^{{VIEWPORT}}^${VIEWPORT}^g" \
        -e "s^{{NOW}}^${NOW}^g" \
        -e "s^{{DEV}}^${DEV}^g" \
        -e "s^{{LOGTITLE}}^${LOGTITLE}^g" \
        -e "s^{{USER}}^${USER}^g" \
        -e "s^{{PROJNAME}}^${PROJNAME}^g" \
        -e "s^{{PROJCLIENT}}^${PROJCLIENT}^g" \
        -e "s^{{CLIENTLOGO}}^${CLIENTLOGO}^g" \
        -e "s^{{DEVURL}}^${DEVURL}^g" \
        -e "s^{{PRODURL}}^${PRODURL}^g" \
        -e "s^{{COMMITURL}}^${COMMITURL}^g" \
        -e "s^{{EXITCODE}}^${EXITCODE}^g" \
        -e "s^{{COMMITHASH}}^${COMMITHASH}^g" \
        -e "s^{{NOTES}}^${notes}^g" \
        -e "s^{{USER}}^${USER}^g" \
        -e "s^{{LOGURL}}^${LOGURL}^g" \
        -e "s^{{REMOTEURL}}^${REMOTEURL}^g" \
        -e "s^{{VIEWPORTPRE}}^${VIEWPORTPRE}^g" \
        -e "s^{{PATHTOREPO}}^${WORKPATH}/${APP}^g" \
        -e "s^{{PROJNAME}}^${PROJNAME}^g" \
        -e "s^{{CLIENTLOGO}}^${CLIENTLOGO}^g" \
        -e "s^{{DEVURL}}^${DEVURL}^g" \
        -e "s^{{PRODURL}}^${PRODURL}^g" \
        -e "s^{{DEFAULT}}^${DEFAULTC}^g" \
        -e "s^{{PRIMARY}}^${PRIMARYC}^g" \
        -e "s^{{SUCCESS}}^${SUCCESSC}^g" \
        -e "s^{{INFO}}^${INFOC}^g" \
        -e "s^{{WARNING}}^${WARNINGC}^g" \
        -e "s^{{DANGER}}^${DANGERC}^g" \
        -e "s^{{SMOOCHID}}^${SMOOCHID}^g" \
        -e "s^{{GRAVATARURL}}^${REMOTEURL}\/${APP}\/avatar^g" \
        -e "s^{{DIGESTWRAP}}^${DIGESTWRAP}^g" \
        -e "s^{{GREETING}}^${GREETING}^g" \
        -e "s^{{REMOTEURL}}^${REMOTEURL}^g" \
        -e "s^{{ANALYTICSMSG}}^${ANALYTICSMSG}^g" \
        -e "s^{{STATURL}}^${REMOTEURL}\/${APP}\/stats^g" \
        -e "s^{{WEEKOF}}^${WEEKOF}^g" \
        "${htmlFile}"        
}
