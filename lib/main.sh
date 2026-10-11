#!/usr/bin/env bash
#
# main.sh
#
###############################################################################
# The main application
###############################################################################

main() {
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
    build_digest
  elif [[ "${REPORT}" == "1" ]]; then
    build_report
  elif [[ "${CREATE_INVOICE}" == "1" ]]; then
    create_invoice
  elif [[ "${SCAN}" == "1" ]]; then
    scan_host
  else
    server_check     # Check that servers are up and running
    
    if [[ "${DISABLE_SSH_CHECK}" != "TRUE" ]]; then
      ssh_check   # Check keys
    fi
    if [[ "${PUBLISH}" == "1" ]]; then
      deploy_project   # Deploy project to live server
    else
      git_checkout "${MASTER}"    # Checkout master branch
      git_gc                 # If needed, clean up the trash

      # A simple way to repair a failed push
      if [[ "${REPAIR}" == "1" ]]; then 
        pre_deploy     # Get the status  

        confirm_branch "${MASTER}"
        git_push
        if [[ -n "${STAGING}" ]]; then
          git_checkout "${STAGING}"
          git_merge
          git_push
        fi

        if [[ -n "${PRODUCTION}" ]]; then
          git_checkout "${PRODUCTION}"
          git_merge
          git_push
        fi
  
        git_checkout "${MASTER}"

        deploy_project      # Deploy project to live server
        return 0
      else
        pre_deploy
      fi

      # Continue normally
      wp_main       # Run Wordpress upgrades if needed
      build_check   # Run package manager
      git_status    # Make sure there's something here to commit
      git_stage     # Stage files
      git_commit    # Commit, with message
      confirm_branch "${MASTER}"
      git_push

      if [[ "${MERGE}" == "1" ]]; then
        if [[ -n "${STAGING}" ]]; then
          git_checkout "${STAGING}"
          git_merge
          git_push
        fi

        if [[ -n "${PRODUCTION}" ]]; then
          git_checkout "${PRODUCTION}"
          git_merge
          git_push
        fi
        git_checkout "${MASTER}"
      fi

      deploy_project   # Deploy project to live server
    fi
  fi  
}
