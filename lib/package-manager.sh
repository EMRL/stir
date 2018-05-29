#!/usr/bin/env bash
#
# package-manager
#
###############################################################################
# Checks if project uses node.js or grunt, and runs package manager if needed. 
###############################################################################
trace "Loading build management"

# Initialize variables
read -r deploy_config SKIP_BUILD <<< ""
echo "${deploy_config} ${SKIP_BUILD}" > /dev/null

function pkgMgr() {
	if [[ "${FORCE}" != "1" ]] || [[ "${BUILD}" == "1" ]]; then
		if [[ "${UPGRADE}" != "1" ]]; then

			# Checking for app/lib, which assumes we're using Grunt
			if [[ -f "${WORKPATH}/${APP}/Gruntfile.coffee" ]]; then
				notice "Found grunt configuration!" 

				if  [[ "${FORCE}" = "1" ]] || yesno --default no "Build assets? [y/N] "; then
					cd "${WORKPATH}"/"${APP}" || errorCheck
		
					if [[ "${VERBOSE}" == "TRUE" ]]; then
						/usr/local/bin/grunt build --force 2>&1 | tee --append "${trshFile}"           
					else
						/usr/local/bin/grunt build --force &>> "${trshFile}" &
						spinner $!
						info "Packages successfully compiled."
					fi
				else
					info "Skipping Grunt..."
				fi
			else
				sleep 1

				# node.js check
				if [[ -f "${WORKPATH}/${APP}${WPROOT}${WPAPP}/themes/${APP}/package.json" ]]; then
					trace "${WORKPATH}/${APP}${WPROOT}${WPAPP}/themes/${APP}/package.json found."
					notice "Found npm configuration!" 

					check_build_method
					if [[ "${SKIP_BUILD}" == "1" ]]; then
						return
					fi

					if [[ "${BUILD}" = "1" ]] || yesno --default no "Build assets? [y/N] "; then
						cd "${WORKPATH}/${APP}${WPROOT}${WPAPP}/themes/${APP}" || errorCheck

						if [[ "${VERBOSE}" == "TRUE" ]]; then
							npm run build | tee --append "${trshFile}"               
						else
							npm run build &>> "${trshFile}" &
							spinner $!   
							info "Packages successfully compiled."
						fi
					else
						info "Skipping Node Package Manager..."
					fi
				else
					# info "No package management needed."
					trace "${WORKPATH}/${APP}${WPROOT}${WPAPP}/themes/$APP/package.json not found, skipping."
				fi
			fi
		fi
	fi
}

# Check deployment method, and determine if it includes a build upon each 
# deployment.
function check_build_method() {
	if [[ "${DEPLOY}" == *"mina"* ]]; then
		deploy_config="$(cat ${WORKPATH}/${APP}/Minafile)"
		if [[ "${deploy_config}" =~ "npm run build" ]] && [[ "${BUILD}" != "1" ]]; then
			SKIP_BUILD="1"
		fi
	fi
}
