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
  env_check         # Check for configuration files that need updating
  wp_check          # Check for Wordpress
  
  if [[ "${RESET}" == "1" ]]; then
    reset_local
  fi

  if [[ -n "${PREPARE}" ]]; then
    if [[ "${PREPARE}" != "FALSE" ]]; then
      prepare
    else
      return
    fi
  fi

  gitStart          # Check for a valid git project and project set up
  lock              # Create lock file
  go                # Start a work session

  if [[ "${DIGEST}" == "1" ]]; then
    create_digest
  elif [[ "${REPORT}" == "1" ]]; then
    create_report
  elif [[ "${CREATE_INVOICE}" == "1" ]]; then
    # create_invoice
    create_invoice
  elif [[ "${SCAN}" == "1" ]]; then
    scan_host
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
        notice "Approval queue functions are deprecated and will be removed soon."
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
        wp          # Run Wordpress upgrades if needed
        pkgMgr      # Run package manager
        gitStatus   # Make sure there's something here to commit         
      fi

      if [[ "${REQUIREAPPROVAL}" == "TRUE" ]] && [[ ! -f "${WORKPATH}/${APP}/.queued" ]]; then
        notice "Approval queue functions are deprecated and will be removed soon."
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
