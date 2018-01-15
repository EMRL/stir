#!/bin/bash
#
# permissions-fix.sh
#
###############################################################################
# Repairs potential permission issues before deployment
###############################################################################
trace "Loading permissions fixes"

function permFix() {
  if [[ "${FIXPERMISSIONS}" == "TRUE" ]]; then
    notice "Setting permissions..."    
  
    # /lib is obsolete for future repositories
    if [[ -d "$WORKPATH/$APP/lib" ]]; then
      sudo chown -R "${DEVUSER}"."${DEVGROUP}" "${WORKPATH}"/"${APP}"/lib; #error_check
      info " ${APP}/lib/"
    else
      sleep 1
    fi

    # Set permissions
      if [[ -f "${WORKPATH}"/"${APP}"/.gitignore ]]; then
      sudo chown -R "${DEVUSER}"."${DEVGROUP}" "${WORKPATH}"/"${APP}"/.gitignore; > /dev/null;
      fi
    
    if [ -f "${WORKPATH}"/"${APP}"/.gitmodules ]; then
      sudo chown -R "${DEVUSER}"."${DEVGROUP}" "${WORKPATH}"/"${APP}"/.gitmodules; > /dev/null; 
    fi
  
    sudo chown -R "${DEVUSER}"."${DEVGROUP}" "${WORKPATH}"/"${APP}"/.git; #error_check
    info " ${APP}/.git"
    sudo chown -R "${DEVUSER}"."${DEVGROUP}" "${WORKPATH}"/"${APP}"/public/system; #error_check
    info " ${APP}/public/system/"
    sudo chown -R "${DEVUSER}"."${DEVGROUP}" "${WORKPATH}"/"${APP}"/public/app; #error_check
    info " ${APP}/public/app/"
    sudo chown -R "${APACHEUSER}"."${APACHEGROUP}" "${WORKPATH}"/"${APP}"/public/app; #error_check
    info " ${APP}/public/app/plugins"
  fi
}
