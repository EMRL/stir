#!/bin/bash
#
# core.sh
#
###############################################################################
# The core application
###############################################################################

function coreApp() {
  depCheck    # Check that required commands are available
  gitStart    # Check for a valid git project and get set up
  lock        # Create lock file
  go          # Start a deployment work session
  if [[ "${DIGEST}" == "1" ]]; then
    createDigest
  elif [[ "${REPORT}" == "1" ]]; then
    createReport
  else
    srvCheck    # Check that servers are up and running
    if [[ "${DISABLESSHCHECK}" != "TRUE" ]]; then
      sshChk    # Check keys
    fi
    permFix     # Fix permissions
    if [[ "${PUBLISH}" == "1" ]]; then
      pkgDeploy   # Deploy project to live server
    else
      gitChkMstr    # Checkout master branch
      gitGarbage    # If needed, clean up the trash

      if [[ ! -f "${WORKPATH}/${APP}/.queued" ]]; then
        preDeploy   # Get the status
      fi

      # Check for approval/deny/queue
      if [[ "${REQUIREAPPROVAL}" == "TRUE" ]] && [[ -f "${WORKPATH}/${APP}/.queued" ]]; then
        if [[ "${APPROVE}" == "1" ]] || [[ -f "${WORKPATH}/${APP}/.approved" ]]; then
          approve   # Approve proposed changes
        else
          if [[ "${DENY}" == "1" ]] || [[ -f "${WORKPATH}/${APP}/.denied" ]]; then 
            deny    # Deny proposed changes
          fi
        fi
      fi

      # Continue normally
      if [[ "${APPROVE}" != "1" ]]; then
        wpPkg       # Run Wordpress upgrades if needed
        pkgMgr      # Run package manager
        gitStatus   # Make sure there's anything here to commit         
      fi

      if [[ "${REQUIREAPPROVAL}" == "TRUE" ]] && [[ ! -f "${WORKPATH}/${APP}/.queued" ]]; then
        queue 		# Queue for approval if needed
      fi

      if [[ "${APPROVE}" != "1" ]] && [[ ! -f "${WORKPATH}/${APP}/.queued" ]]; then
        gitStage    # Stage files     
        gitCommit   # Commit, with message
      fi

      # Push, merge, deploy
      gitPushMstr   # Push master branch
      gitChkProd    # Checkout production branch
      gitMerge      # Merge master into production
      gitPushProd   # Push production branch
      gitChkMstr    # Checkout master once again  
      pkgDeploy     # Deploy project to live server
    fi
  fi  
}
