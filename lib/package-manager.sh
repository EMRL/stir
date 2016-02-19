#!/bin/bash
#
# pkgMgr()
#
# Checks if project uses node.js, and runs package manager if needed.
# Also checks for Grunt, for our own internal backward compatibility.
trace "Loading pkgMgr()"

function pkgMgr() {
	if [ "${FORCE}" != "1" ]; then
		if [ "${UPGRADE}" != "1" ]; then
			notice "Checking for package manager..." 

			# Checking for app/lib, which assumes we're using Grunt
			if [ -f "${WORKPATH}/${APP}/Gruntfile.coffee" ]
				then
		
				if  [ "${FORCE}" = "1" ] || yesno --default no "Run Grunt? [y/N] "; then
					cd "${WORKPATH}"/"${APP}" || errorCheck
		
					if [[ "${VERBOSE}" -eq 1 ]]; then
						# sudo /usr/local/bin/grunt build --force 2>&1 | tee --append $trshFile
						/usr/local/bin/grunt build --force 2>&1 | tee --append "${trshFile}"
						trace "Output from grunt is not currently being logged, sorry."           
					else
						# sudo /usr/local/bin/grunt build --force &>> $trshFile &
						/usr/local/bin/grunt build --force &>> "${trshFile}" &
						spinner $!
						trace "Output from grunt is not currently being logged, sorry."
						info "Packages successfully compiled."
					fi
				else
					info "Skipping Grunt..."
				fi
			else
				sleep 1
		
				# node.js check
				if [ -f "$WORKPATH/$APP/public/app/themes/$APP/package.json" ]; then
					trace "$WORKPATH/$APP/public/app/themes/$APP/package.json found."

					if  [ "$FORCE" = "1" ] || yesno --default no "Run Node Package Manager? [y/N] "; then
						cd "${WORKPATH}"/"${APP}"/public/app/themes/"${APP}" || errorCheck

						if [[ $VERBOSE -eq 1 ]]; then
							npm run build | tee --append "${trshFile}"
							trace "Output from npm is not currently being logged, sorry."                
						else
							npm run build  &>> "${trshFile}" &
							spinner $!
							trace "Output from npm is not currently being logged, sorry."    
							info "Packages successfully compiled."
						fi
					else
						info "Skipping Node Package Manager..."
					fi
				else
					info "No package management needed."
					trace "$WORKPATH/$APP/public/app/themes/$APP/package.json not found, skipping."
				fi
			fi
		fi
	fi
}
