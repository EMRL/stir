#!/bin/bash
#
# permfix()
#
# Repairs potential permission issues before deployment; in 
# the future this should never be needed
trace "Loading permFix()"

function permFix() {
	if [ "${FIXPERMISSIONS}" == "TRUE" ]; then
		notice "Setting permissions..."    
  
		# /lib is obsolete for future repositories
		if [ -d "$WORKPATH/$APP/lib" ]; then
			sudo chown -R "${DEVUSER}"."${DEVGROUP}" "${WORKPATH}"/"${APP}"/lib; #errorChk
			info " ${APP}/lib/"
		else
			sleep 1
		fi

		# Set permissions
	  	if [ -f "${WORKPATH}"/"${APP}"/.gitignore ]; then
			sudo chown -R "${DEVUSER}"."${DEVGROUP}" "${WORKPATH}"/"${APP}"/.gitignore; > /dev/null;
	  	fi
	  
		if [ -f "${WORKPATH}"/"${APP}"/.gitmodules ]; then
			sudo chown -R "${DEVUSER}"."${DEVGROUP}" "${WORKPATH}"/"${APP}"/.gitmodules; > /dev/null; 
		fi
	
		sudo chown -R "${DEVUSER}"."${DEVGROUP}" "${WORKPATH}"/"${APP}"/.git; #errorChk
		info " ${APP}/.git"
		sudo chown -R "${DEVUSER}"."${DEVGROUP}" "${WORKPATH}"/"${APP}"/public/system; #errorChk
		info " ${APP}/public/system/"
		sudo chown -R "${DEVUSER}"."${DEVGROUP}" "${WORKPATH}"/"${APP}"/public/app; #errorChk
		info " ${APP}/public/app/"
		sudo chown -R "${APACHEUSER}"."${APACHEGROUP}" "${WORKPATH}"/"${APP}"/public/app; #errorChk
		info " ${APP}/public/app/plugins"
	fi
}
