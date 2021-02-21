#!/usr/bin/env bash
#
# main.sh
#
###############################################################################
# The main application
###############################################################################

function main() {
  user_tests            # Run tests if specified by the user
  release_check         # Check for newer version at Github
  env_check             # Check for configuration files that need updating
  set_fallback_values   # Set undefined variables to something useful
  wp_check              # Check for Wordpress
  
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

  verify_project    # Check for a valid git project and project set up
  lock              # Create lock file
  go                # Start a work session

  if [[ "${DIGEST}" == "1" ]]; then
    create_digest
  elif [[ "${REPORT}" == "1" ]]; then
    create_report
  elif [[ "${CREATE_INVOICE}" == "1" ]]; then
    create_invoice
  elif [[ "${SCAN}" == "1" ]]; then
    scan_host
  else
    check_server      # Check that servers are up and running
    
    if [[ "${DISABLE_SSH_CHECK}" != "TRUE" ]]; then
      ssh_check   # Check keys
    fi
    if [[ "${PUBLISH}" == "1" ]]; then
      deploy_project   # Deploy project to live server
    else
      checkout "${MASTER}"    # Checkout master branch
      garbage                 # If needed, clean up the trash

      # A simple way to repair a failed push
      if [[ "${REPAIR}" == "1" ]]; then 
        pre_deploy     # Get the status  

        confirm_branch "${MASTER}"
        push
        if [[ -n "${STAGING}" ]]; then
          checkout "${STAGING}"
          merge
          push
        fi

        if [[ -n "${PRODUCTION}" ]]; then
          checkout "${PRODUCTION}"
          merge
          push
        fi
  
        checkout "${MASTER}"

        deploy_project      # Deploy project to live server
        return 0
      elif [[ ! -f "${WORK_PATH}/${APP}/.queued" ]]; then
        pre_deploy      # Get the status
      fi


      # Check for approval/deny/queue
      if [[ "${REQUIRE_APPROVAL}" == "TRUE" ]] && [[ -f "${WORK_PATH}/${APP}/.queued" ]]; then
        notice "Approval queue functions are deprecated and will be removed soon."
        if [[ "${APPROVE}" == "1" ]] || [[ -f "${WORK_PATH}/${APP}/.approved" ]]; then
          approve     # Approve proposed changes
        else
          if [[ "${DENY}" == "1" ]] || [[ -f "${WORK_PATH}/${APP}/.denied" ]]; then 
            deny      # Deny proposed changes
          fi
        fi
      fi

      # Continue normally
      if [[ "${APPROVE}" != "1" ]]; then
        wp_main       # Run Wordpress upgrades if needed
        build_check   # Run package manager
        status        # Make sure there's something here to commit         
      fi

      if [[ "${REQUIRE_APPROVAL}" == "TRUE" ]] && [[ ! -f "${WORK_PATH}/${APP}/.queued" ]]; then
        notice "Approval queue functions are deprecated and will be removed soon."
        queue 		    # Queue for approval if needed
      fi

      if [[ "${APPROVE}" != "1" ]] && [[ ! -f "${WORK_PATH}/${APP}/.queued" ]]; then
        stage         # Stage files     
        commit     # Commit, with message
      fi 
      
      confirm_branch "${MASTER}"
      push

      if [[ "${MERGE}" == "1" ]]; then
        if [[ -n "${STAGING}" ]]; then
          checkout "${STAGING}"
          merge
          push
        fi

        if [[ -n "${PRODUCTION}" ]]; then
          checkout "${PRODUCTION}"
          merge
          push
        fi
        checkout "${MASTER}"
      fi

      deploy_project     # Deploy project to live server
    fi
  fi  
}
