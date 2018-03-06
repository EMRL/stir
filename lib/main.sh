#!/usr/bin/env bash
#
# main.sh
#
###############################################################################
# The main application
###############################################################################

function main() {
  dependency_check  # Check that required commands are available
  release_check     # Check for newer version at Github
  env_check      # Check for configuration files that need updating
  gitStart          # Check for a valid git project and get set up
  lock              # Create lock file
  go                # Start a deployment work session

  if [[ "${DIGEST}" == "1" ]]; then
    create_digest
  elif [[ "${REPORT}" == "1" ]]; then
    create_report
  elif [[ "${CREATE_INVOICE}" == "1" ]]; then
    create_invoice
  else
    server_check      # Check that servers are up and running
    if [[ "${DISABLESSHCHECK}" != "TRUE" ]]; then
      ssh_check   # Check keys
    fi
    permFix     # Fix permissions
    if [[ "${PUBLISH}" == "1" ]]; then
      pkgDeploy   # Deploy project to live server
    else
      gitChkMstr    # Checkout master branch
      gitGarbage    # If needed, clean up the trash

      # A simple way to repair a failed push
      if [[ "${REPAIR}" == "1" ]]; then 
        preDeploy     # Get the status
        gitPushMstr   # Push master branch
        gitChkProd    # Checkout production branch
        gitMerge      # Merge master into production
        gitPushProd   # Push production branch
        gitChkMstr    # Checkout master once again  
        pkgDeploy     # Deploy project to live server
        return 0
      elif [[ ! -f "${WORKPATH}/${APP}/.queued" ]]; then
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
