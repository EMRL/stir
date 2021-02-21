#!/usr/bin/env bash
#
# migrate.sh
#
###############################################################################
# A ridiculous method of migrating deprecated 
###############################################################################

function migrate_variables {
  if [[ -z "${i}" ]]; then
    echo "Can't find target file"
    exit 1
  elif
    grep -aq 'WORKPATH\|PROJNAME\|CLEARSCREEN' "${i}"; then
    echo "Migrating ${i}..."

    sed -i -e 's^ACCESSTOKEN^ACCESS_TOKEN^g' \
      -e 's^ACTIVECHECK^CHECK_ACTIVE^g' \
      -e 's^ACFKEY^ACF_KEY^g' \
      -e 's^ALLOWROOT^ALLOW_ROOT^g' \
      -e 's^ADDTIME^ADD_TIME^g' \
      -e 's^AUTHORIZATIONCODE^AUTHORIZATION_CODE^g' \
      -e 's^CHECKACTIVE^CHECK_ACTIVE^g' \
      -e 's^CHECKBRANCH^CHECK_BRANCH^g' \
      -e 's^CHECKSERVER^CHECK_SERVER^g' \
      -e 's^CHECKTIME^CHECK_TIME^g' \
      -e 's^CLEARSCREEN^CLEAR_SCREEN^g' \
      -e 's^CLIENTCONTACT^CLIENT_CONTACT^g' \
      -e 's^CLIENTID^CLIENT_ID^g' \
      -e 's^CLIENTLOGO^CLIENT_LOGO^g' \
      -e 's^CLIENTSECRET^CLIENT_SECRET^g' \
      -e 's^CONFIGDIR^CONFIG_DIR^g' \
      -e 's^DEVURL^DEV_URL^g' \
      -e 's^DIGESTEMAIL^DIGEST_EMAIL^g' \
      -e 's^DIGESTSLACK^DIGEST_SLACK^g' \
      -e 's^DISABLESSHCHECK^DISABLE_SSH_CHECK^g' \
      -e 's^DONOTDEPLOY^DO_NOT_DEPLOY^g' \
      -e 's^DONOTUPDATEWP^DO_NOT_UPDATE_WP^g' \
      -e 's^EMAILERROR^EMAIL_ERROR^g' \
      -e 's^EMAILHTML^EMAIL_HTML^g' \
      -e 's^EMAILQUIT^EMAIL_QUIT^g' \
      -e 's^EMAILSUCCESS^EMAIL_SUCCESS^g' \
      -e 's^EXPIRELOGS^EXPIRE_LOGS^g' \
      -e 's^FROMDOMAIN^FROM_DOMAIN^g' \
      -e 's^FROMUSER^FROM_USER^g' \
      -e 's^GITSTATS^GIT_STATS^g' \
      -e 's^HTMLTEMPLATE^HTML_TEMPLATE^g' \
      -e 's^INCLUDEHOSTING^INCLUDE_HOSTING^g' \
      -e 's^LOCALHOSTPATH^LOCAL_HOST_PATH^g' \
      -e 's^LOCALHOSTPOST^POST_TO_LOCAL_HOST^g' \
      -e 's^MONITORPASS^MONITOR_PASS^g' \
      -e 's^MONITORURL^MONITOR_URL^g' \
      -e 's^MONITORUSER^MONITOR_USER^g' \
      -e 's^NOKEY^NO_KEY^g' \
      -e 's^NOPHP^NO_PHP^g' \
      -e 's^POSTEMAILHEAD^POST_EMAIL_HEAD^g' \
      -e 's^POSTEMAILTAIL^POST_EMAIL_TAIL^g' \
      -e 's^POSTTOSLACK^POST_TO_SLACK^g' \
      -e 's^POSTURL^POST_URL^g' \
      -e 's^PRODURL^PROD_URL^g' \
      -e 's^PROFILEID^PROFILE_ID^g' \
      -e 's^PROJCLIENT^PROJECT_CLIENT^g' \
      -e 's^PROJNAME^PROJECT_NAME^g' \
      -e 's^REDIRECTURI^REDIRECT_URI^g' \
      -e 's^REFRESHTOKEN^REFRESH_TOKEN^g' \
      -e 's^REMOTELOG^REMOTE_LOG^g' \
      -e 's^REMOTETEMPLATE^REMOTE_TEMPLATE^g' \
      -e 's^REMOTEURL^REMOTE_URL^g' \
      -e 's^REPOHOST^REPO_HOST^g' \
      -e 's^REQUIREAPPROVAL^REQUIRE_APPROVAL^g' \
      -e 's^SCPHOST^SCP_HOST^g' \
      -e 's^SCPHOSTPATH^SCP_HOST_PATH^g' \
      -e 's^SCPPASS^SCP_PASS^g' \
      -e 's^SCPPORT^SCP_PORT^g' \
      -e 's^SCPPOST^SCP_POST^g' \
      -e 's^SCPUSER^SCP_USER^g' \
      -e 's^SERVERCHECK^CHECK_SERVER^' \
      -e 's^SERVERID^SERVER_ID^g' \
      -e 's^SHORTEMAIL^SHORT_EMAIL^g' \
      -e 's^SLACKERROR^SLACK_ERROR^g' \
      -e 's^SLACKURL^SLACK_URL^g' \
      -e 's^SMARTCOMMIT^SMART_COMMIT^g' \
      -e 's^TASKUSER^TASK_USER^g' \
      -e 's^WFCHECK^WF_CHECK^g' \
      -e 's^WORKPATH^WORK_PATH^g' \
      -e 's^WPAPP^WP_APP^g' \
      -e 's^WPCLI^WP_CLI^g' \
      -e 's^WPROOT^WP_ROOT^g' \
      -e 's^WPSYSTEM^WP_SYSTEM^g' \
    "${i}"

    if [[ "${local_version}" == "null" ]]; then
      echo "Done."; exit
    else   
      info "Configuration file migrated - restart stir to continue update."
      quiet_exit
    fi
  else
    if [[ MIGRATE == "1" ]]; then
      echo "Global configuration does not need migrating."
      exit
    else
      return
    fi
  fi
}
