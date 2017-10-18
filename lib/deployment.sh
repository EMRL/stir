#!/bin/bash
#
# deployment.sh
#
###############################################################################
# Handles deployment-related tasks
###############################################################################
trace "Loading deployment functions"   

# Housekeeping tasks to run before final deployment
function preDeploy() {
  # If there are changes waiting in the repo, stop and ask for user input
  # This should probably be it's own function
  currentStash="0"
  if [[ -z $(git status --porcelain) ]]; then
    trace "Status looks good"
  else
    # If running in --force mode we will not allow deployment to continue
    if [[ "${FORCE}" == "1" && "${APPROVE}" != "1" ]] || [[ "${UPDATEONLY}" == "1" ]]; then
      trace "Checking for files that need stashing"
      # Stash the dirty bits
      if [[ "${STASH}" == "TRUE" ]] || [[ "${UPDATEONLY}" == "1" ]]; then # Bah, clunky
        emptyLine
        trace "Stashing dirty files"
        if [[ "${VERBOSE}" == "1" ]] && [[ "${QUIET}" != "1" ]]; then
          git stash | tee --append "${logFile}"; errorChk 
        else
          git stash >> "${logFile}"; errorChk
        fi
        currentStash="1"
      else
        emptyLine
        error "There are previously undeployed changes in this project, deployment can not continue."
      fi

    else
      emptyLine
      warning "There are previously undeployed changes in this project."

      if yesno --default no "View unresolved files? [y/N] "; then
        console; console " N = New | M = Modified | D = Deleted"
        console " ------------------------------------ "
        git status --porcelain; echo
        if  yesno --default yes "Continue deploy? [Y/n] "; then
          trace "Continuing deploy"
        else
          userExit
        fi
      fi
    fi
  fi
} 

function pkgDeploy() {
  # There are problems with code right now. The changes I made to pass shellcheck
  # broke the deployment command getting passed through. Looks like I need to do some 
  # stuff with eval, see http://emrl.co/s6chq
  emptyLine
  if [[ -n "${DEPLOY}" ]]; then
    # Add ssh keys and double check directoy
    cd "${WORKPATH}/${APP}" || errorChk
    if [[ "${INCOGNITO}" != "TRUE" ]]; then
      trace "Launching deployment"
    else
      trace "Launching deployment from ${PWD}"
    fi
    fixIndex
    
    # Make sure the project's deploy command is going to work
    deploy_cmd=$(echo "${DEPLOY}" | awk '{print $1;}')
    hash "${deploy_cmd}" 2>/dev/null || {
      warning "Your deployment command ${deploy_cmd} cannot be found.";
    }

    if [[ "${REQUIREAPPROVAL}" != "TRUE" ]]; then
      # If we don't require approval to push to live, keep going
      if [[ "${FORCE}" = "1" ]] || yesno --default yes "Deploy to live server? [Y/n] "; then
        # Test deployment command before running
        deployChk
        # Deploy via deployment command specified in configuration
        if [[ "${VERBOSE}" == "1" ]] && [[ "${INCOGNITO}" != "TRUE" ]]; then
          eval "${DEPLOY}" | tee --append "${logFile}"
          errorChk
        else
          if [[ "${QUIET}" != "1" ]]; then
            eval "${DEPLOY}" &>> "${logFile}" &
            spinner $!
          else
            eval "${DEPLOY}" &>> "${logFile}"
            errorChk
          fi
        fi

        # Check for deployment failure
        if [[ "${EXITCODE}" == "0" ]]; then
          trace "Deployment success"
        fi

      else
        # If running --publish exit now
        [[ "${PUBLISH}" == "1" ]] && quietExit
      fi
    else
      if [[ "${APPROVE}" == "1" ]]; then
        eval "${DEPLOY}" &>> "${logFile}"
      else
        if [[ "${APPROVE}" != "1" ]]; then
          if [[ -z "${PRODURL}" ]]; then 
            warning "This project requires approval but has no production URL configured."
          else
            info "The project requires approval before pushing to ${PRODURL}"
          fi
        fi
      fi
    fi
  fi
  postDeploy
}

function postDeploy() {
  # Check for deployment failure
  if grep -q "ERROR: Deploy failed." "${logFile}"; then
    error "Deploy failed."
  fi

  if [[ "${APPROVE}" != "1" ]] && [[ "${PUBLISH}" != "1" ]]; then
    # We just attempted to deploy, check for changes still waiting in the repo
    # if we find any, something went wrong.

    if [[ -z $(git status -uno --porcelain) ]]; then
      # Run integration hooks
      postCommit  
      # This needs a check.
      # info "Deployment Success."
    else
      info ""
      if yesno --default yes "Deployment succeeded, but something unexpected happened. View status? [Y/n] "; then
        git status
      fi
    fi
  else
    # Run integration hooks
    postCommit
    # This needs a check.
    if [[ "${APPROVE}" == "1" ]] || [[ "${REQUIREAPPROVAL}" != "TRUE" ]]; then
      if [[ -z "${PRODURL}" ]]; then
        warning "No production URL configured."
        info "Successfully deployed."
      else
        info "Deployed to ${PRODURL}"
      fi
    fi
  fi
} 
