#!/usr/bin/env bash
#
# reset.sh
#
###############################################################################
# Deletes local repo files, while keeping configuration intact
###############################################################################

function reset_local() {
  if [[ -n "${project_config}" ]] && [[ -w "${WORKPATH}/${APP}" ]]; then
    info "Resetting local files..."
      
    trace "mv ${project_config} /tmp/${APP}-stir.sh"
    mv "${project_config}" /tmp/"${APP}"-stir.sh
        
    trace "rm -rfv ${WORKPATH}/${APP}/*"
    rm -rfv ${WORKPATH}/${APP}/*
        
    rm -rfv ${WORKPATH}/${APP}/.*
        
    trace "mv /tmp/${APP}-stir.sh ${project_config}"
    mv /tmp/"${APP}"-stir.sh "${project_config}"
    quietExit
  else
    warning "Can not reset this project"
  fi
}
