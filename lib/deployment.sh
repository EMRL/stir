#!/usr/bin/env bash
#
# deployment.sh
#
###############################################################################
# Handles deployment-related tasks
############################################################################### 

# Initializa needed variables
var=(start_deploy)
init_loop

# Housekeeping tasks to run before final deployment
function pre_deploy() {
  # If there are changes waiting in the repo, stop and ask for user input
  # This should probably be it's own function
  current_stash="0"
  if [[ -n $(git status --porcelain) ]]; then
    # If running in --force mode we will not allow deployment to continue
    if [[ "${FORCE}" == "1" && "${APPROVE}" != "1" ]] || [[ "${UPDATEONLY}" == "1" ]] || [[ "${REPAIR}" = "1" ]]; then
      trace "Checking for files that need stashing"
      # Stash the dirty bits
      if [[ "${STASH}" == "TRUE" ]] || [[ "${UPDATEONLY}" == "1" ]]; then # Bah, clunky
        empty_line
        trace "Stashing dirty files"
        if [[ "${VERBOSE}" == "TRUE" ]] && [[ "${QUIET}" != "1" ]]; then
          git stash | tee --append "${log_file}"; error_check 
        else
          git stash >> "${log_file}"; error_check
        fi
        current_stash="1"
      else
        empty_line
        error "There are unstaged changes in this project, deployment can not continue."
      fi

    else
      empty_line
      warning "There are unstaged changes in this project."

      if yesno --default no "View unresolved files? [y/N] "; then
        console; console " N = New | M = Modified | D = Deleted"
        console " ------------------------------------ "
        git status --porcelain; echo
        if  yesno --default yes "Continue? [Y/n] "; then
          trace "Processing project"
        else
          user_exit
        fi
      fi
    fi
  fi
} 

function deploy_project() {
  empty_line
  if [[ -n "${DEPLOY}" ]]; then
    # Add ssh keys and double check directoy
    cd "${APP_PATH}" || error_check
    if [[ "${INCOGNITO}" != "TRUE" ]]; then
      trace "Launching deployment"
    else
      trace "Launching deployment from ${PWD}"
    fi
    
    if [[ "${DEPLOY}" != "SCP" ]]; then
      # Make sure the project's deploy command is going to work
      deploy_cmd=$(echo "${DEPLOY}" | awk '{print $1;}')
      hash "${deploy_cmd}" 2>/dev/null || {
        warning "Your deployment command ${deploy_cmd} cannot be found.";
      }
    fi

    if [[ "${REQUIRE_APPROVAL}" != "TRUE" ]]; then

      # If we don't require approval to push to live, keep going
      if [[ "${FORCE}" == "1" ]] || yesno --default yes "Deploy to live server? [Y/n] "; then
        start_deploy="1"

        # Test deployment command before running
        if [[ "${DEPLOY}" != "SCP" ]]; then
          deploy_check
        fi

        # Deploy via deployment command specified in configuration
        if [[ "${VERBOSE}" == "TRUE" ]] && [[ "${INCOGNITO}" != "TRUE" ]]; then
          if [[ "${DEPLOY}" == "SCP" ]]; then
            deploy_scp
          else
            eval "${DEPLOY}" | tee --append "${log_file}"            
          fi
          error_check
        else
          if [[ "${QUIET}" != "1" ]]; then
            if [[ "${DEPLOY}" == "SCP" ]]; then
              deploy_scp &
              spinner $!
            else
              eval "${DEPLOY}" &>> "${log_file}" &
              spinner $!
            fi
          else
            if [[ "${DEPLOY}" == "SCP" ]]; then
              deploy_scp &>> "${log_file}"; error_check
            else
              eval "${DEPLOY}" &>> "${log_file}"; error_check
            fi
          fi
        fi

        # Check for deployment failure
        if [[ "${EXITCODE}" == "0" ]]; then
          trace "Deployment success"
        fi

      else
        # If running --publish exit now
        [[ "${PUBLISH}" == "1" ]] && quiet_exit
      fi
    else
      if [[ "${APPROVE}" == "1" ]]; then
        eval "${DEPLOY}" &>> "${log_file}"
      else
        if [[ "${APPROVE}" != "1" ]]; then
          if [[ -z "${PROD_URL}" ]]; then 
            warning "This project requires approval but has no production URL configured."
          else
            info "The project requires approval before pushing to ${PROD_URL}"
          fi
        fi
      fi
    fi
  fi
  deploy_cleanup
}

function deploy_cleanup() {
  # Check for deployment failure
  if grep -aq "ERROR: Deploy failed." "${log_file}"; then
    error "Deploy failed."
  fi

  if [[ "${APPROVE}" != "1" ]] && [[ "${PUBLISH}" != "1" ]]; then
    # We just attempted to deploy, check for changes still waiting in the repo
    # if we find any, something went wrong.

    if [[ -z $(git status -uno --porcelain) ]]; then
      # Run integration hooks
      postCommit  
      deploy_msg
    else
      warning "Deployment succeeded, but something unexpected happened."
      if yesno --default yes "View status? [Y/n] "; then
        git status
      fi
    fi
  else
    # Run integration hooks
    postCommit
    # This needs a check.
    if [[ "${APPROVE}" == "1" ]]; then
    	info "Deployment queued for approval."
    else
      if [[ -z "${PROD_URL}" ]]; then
        warning "No production URL configured, but deployment command ran successfully."
      else
        deploy_msg
      fi
    fi
  fi
}

function deploy_msg() {
  if [[ -n "${PROD_URL}" ]] && [[ "${start_deploy}" == "1" ]]; then
    info "Deployed to ${PROD_URL}"
  fi
}
