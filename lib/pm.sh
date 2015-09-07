#!/bin/bash
#
# pm()
#
# Checks if project uses node.js, and runs package manager if needed.
# Also checks for Grunt, for backward compatibility with some of our older projects (Namely CAA)
trace "Loading pm()"
function pm() {
	notice "Checking for package manager..."
	
	# Grunt check
	if [ -d "$WORKPATH/$APP/lib" ]
		then
		if  [ "$FORCE" = "1" ] || yesno --default no "Run Grunt? [y/N] "; then
			cd $WORKPATH/$APP; \
			if [[ $VERBOSE -eq 1 ]]; then
				sudo grunt build --force 2>&1 | tee --append $logFile                
			else
				sudo grunt build --force &>> $logFile &
				spinner $!
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
				cd $WORKPATH/$APP/public/app/themes/$APP; \

				if [[ $VERBOSE -eq 1 ]]; then
					npm run build | tee --append $logFile               
				else
					npm run build  &>> $logFile &
					spinner $!
					info "Packages successfully compiled."
				fi
			else
				info "Skipping Node Package Manager..."
			fi
		else
			trace "$WORKPATH/$APP/public/app/themes/$APP/package.json not found, skipping."
		fi
	fi
}