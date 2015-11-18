#!/bin/bash
#
# wordpress.sh
#
# Checks for Wordpress upgrades, and executes upgrades if needed
#
trace "Loading wordpress.sh"

function wpPkg() {
	# Is wp-cli installed? 
	if hash wp 2>/dev/null; then
	trace "wp-cli found, checking for Wordpress."

		# Check for Wordpress
		if [ -f $WORKPATH/$APP/public/system/wp-settings.php ]; then
			trace "Wordpress found."
			cd $WORKPATH/$APP/public; \
			
			# Look for updates
			#if [[ $VERBOSE -eq 1 ]]; then
			#	wp plugin status | tee --append $logFile $wpFile              
			#	wp core check-update | tee --append $logfile
			#else
				wpCheck &
				spinner $!
			#fi

			# Check the logs
			#if grep -q "U = Update Available" $logFile; then
			if grep -q "Available plugin updates:" $wpFile; then

				# If available then let's do it
				info "The following updates are available:"
				# Clean the garbage out of the log for console display
				sed '1,/update_version/d' $wpFile > $trshFile && mv $trshFile $wpFile;
				awk '{print "  " $1,$4}' $wpFile > $trshFile && mv $trshFile $wpFile;
				# Work around the weird "Available" bug
				sed '/Available/d' $wpFile > $trshFile && mv $trshFile $wpFile;
				cat $wpFile; emptyLine
				if  [ "$FORCE" = "1" ] || yesno --default no "Proceed with updates? [y/N] "; then
					# Check for Wordfence cache file and remove if found
					if [ -f $WORKPATH/$APP/public/app/plugins/wordfence/tmp/configCache.php ]; then
						sudo rm $WORKPATH/$APP/public/app/plugins/wordfence/tmp/configCache.php
					fi

					sudo -u "apache" --  /usr/local/bin/wp plugin update --all &>> $logFile &
					spinner $!
					# Any problems with plugin updates?
					if grep -q "Warning: The update cannot be installed because we will be unable to copy some files." $logFile; then
						error "One or more plugin upgrades have failed, probably due to problems with permissions."
					else
						if grep -q "Plugin update failed." $logFile; then
							error "One or more plugin upgrades have failed."
						else
							trace "OK"
						fi
						trace "OK"
					fi

					cd $WORKPATH/$APP/; \
					info "Plugin updates complete."
				else
					info "Skipping plugin updates..."
				fi
			else
				info "Plugins are up to date."; UPD1="1"
			fi

			# Check log for core updates
			# There's a little bug when certain plugins are spitting errors; work around seems to be 
			# to check for core updates a second time
			cd $WORKPATH/$APP/public; \
			wp core check-update &>> $logFile
			if grep -q "Success: WordPress is at the latest version." $logFile; then
				info "Wordpress core is up to date."; UPD2="1"
			else
				sleep 1
				# Get files setup for smart commit
				wp core check-update &> $coreFile
				# Strip out any randomly occuring debugging output
				grep -vE "Notice:|Warning:|Strict Standards:|PHP" $coreFile > $trshFile && mv $trshFile $coreFile;
				# This is the old methond, for some reason is stopped working
				# awk 'FNR == 1 {next} {print $1}' $coreFile > $trshFile && mv $trshFile $coreFile;
				cat $coreFile | awk 'FNR == 1 {next} {print $1}' > $trshFile && mv $trshFile $coreFile;
				# The code below is no longer needed
				# Just in case, try to remove all blank lines. DOS formatting is messing up output with PHP crap
				# sed -n -E -e '/version/,$ p' $coreFile > $trshFile && mv $trshFile $coreFile;
				COREUPD=$(<$coreFile)

				# Update available!  \o/
				echo -e "";
				if  [ "$FORCE" = "1" ] || yesno --default no "A new version of Wordpress is available ("$COREUPD"), update? [y/N] "; then
					cd $WORKPATH/$APP/public; \
					# Need to make filepath a variable
					sudo -u "apache" --  /usr/local/bin/wp core update &>> $logFile &
					# wp core update &>> $logFile &
					spinner $!
					# Double check upgrade was successful
					wp core check-update --quiet &> $trshFile
					if grep -q "version" $trshFile; then
						error "Core update failed.";
					fi
					sleep 1
					cd $WORKPATH/$APP/; \
					info "Upgrading development database..."; lynx -dump $DEVURL/system/wp-admin/upgrade.php > $trshFile
					info "Upgrading production database..."; lynx -dump $PRODURL/system/wp-admin/upgrade.php > $trshFile
					info "Wordpress core updates complete."; UPDCORE=1

				else
					info "Skipping Wordpress core updates..."
				fi   
			fi
		else
			trace "Wordpress not found."
		fi
	else
		trace "wp-cli not found, skipping Wordpress updates."
	fi

	# If running in Wordpress update-only mode, bail out
	if [ "$UPGRADE" = "1" ] && [ "$UPD1" = "1" ] && [ "$UPD2" = "1" ]; then
		info "No updates available, halting deployment."
		safeExit
	fi
}

function wpCheck() {
	notice "Checking for updates..."
	# This is uper ghetto :[
	wp plugin status &>> $logFile
	wp plugin update --dry-run --all &> $wpFile
	# Probably going to let this stay commented out
	# wp core check-update &>> $logFile
}