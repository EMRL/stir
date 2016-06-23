#!/bin/bash
#
# wordpress.sh
#
# Checks for Wordpress upgrades, and executes upgrades if needed
#
trace "Loading wordpress.sh"

function wpPkg() {

	# Make sure we are allowed to update
	if [ "${SKIPUPDATE}" != "1" ]; then

		# Is wp-cli installed? 
		if hash wp 2>/dev/null; then
		trace "wp-cli found, checking for Wordpress."

			# Check for Wordpress
			if [ -f $WORKPATH/$APP/public/system/wp-settings.php ]; then
				trace "Wordpress found."
				cd $WORKPATH/$APP/public; \
				
				# Look for updates
				notice "Checking for updates..."
				if [ "${QUIET}" != "1" ]; then
					wpCheck &
					spinner $!
				else
					$WPCLI/wp plugin status --no-color >> $logFile
					$WPCLI/wp plugin update --dry-run --no-color --all > $wpFile
				fi

				# Check the logs
				#if grep -q "U = Update Available" $logFile; then
				if grep -q "Available plugin updates:" $wpFile; then		

					# If available then let's do it
					info "The following updates are available:"
					# Clean the garbage out of the log for console display
					sed 's/[+|]//g' $wpFile > $trshFile && mv $trshFile $wpFile;
					sed '/^\s*$/d' $wpFile > $trshFile && mv $trshFile $wpFile;
					# Remove lines with multiple sequential hyphens
					sed '/--/d' $wpFile > $trshFile && mv $trshFile $wpFile;
					# Remove the column label row
					sed '1,/update_version/d' $wpFile > $trshFile && mv $trshFile $wpFile;
					# Remove everything left but the first and fourth "words"
					awk '{print "  " $1,$4}' $wpFile > $trshFile && mv $trshFile $wpFile;
					# Work around the weird "Available" bug
					sed '/Available/d' $wpFile > $trshFile && mv $trshFile $wpFile;
					# Work around for the odd "REQUEST:" occuring
					sed '/REQUEST:/d' $wpFile > $trshFile && mv $trshFile $wpFile;
					cat $wpFile; emptyLine

					if  [ "$FORCE" = "1" ] ||  yesno --default no "Proceed with updates? [y/N] "; then

						# No longer run as apache
						# sudo -u "apache" --  /usr/local/bin/wp plugin update --all --no-color &>> $logFile &
						if [ "${QUIET}" != "1" ]; then
							# Is Wordfence check enabled?
							if [[ "${WFCHECK}" == "TRUE" ]]; then
								sudo -u "apache" -- /usr/local/bin/wp plugin update --all --no-color &>> $logFile &
								spinner $!
							else
								$WPCLI/wp plugin update --all --no-color &>> $logFile &
								spinner $!
							fi
						else
							$WPCLI/wp plugin update --all --no-color &>> $logFile
						fi	

						# Any problems with plugin updates?
						if grep -q "Warning: The update cannot be installed because we will be unable to copy some files." $logFile; then
							error "One or more plugin upgrades have failed, probably due to problems with permissions."
						else
							if grep -q "Plugin update failed." $logFile; then
								error "One or more plugin upgrades have failed."
							else
								if grep -q "Warning: Update package not available." $logFile; then
									error "One or more update packages are not available. \nThis is often be caused by commercial plugins; check your log files."
								else
									if grep -q "Error: Updated" $logFile; then
										error "One or more plugin upgrades have failed."
									fi
									trace "Update seems OK"
								fi
								trace "Update seems OK"
							fi
							trace "Update seems OK"
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

				if [[ "${WFCHECK}" == "TRUE" ]]; then
					sudo -u "apache" -- $WPCLI/wp core check-update --no-color &>> $logFile
				else
					$WPCLI/wp core check-update --no-color &>> $logFile
				fi

				if grep -q "WordPress is at the latest version." $logFile; then
					info "Wordpress core is up to date."; UPD2="1"
				else
					sleep 1
					# Get files setup for smart commit
					if [[ "${WFCHECK}" == "TRUE" ]]; then
						sudo -u "apache" -- $WPCLI/wp core check-update --no-color &> $coreFile
					else
						$WPCLI/wp core check-update --no-color &> $coreFile
					fi
					# Strip out any randomly occuring debugging output
					grep -vE "Notice:|Warning:|Strict Standards:|PHP" $coreFile > $trshFile && mv $trshFile $coreFile;
					# Clean out the gobbleygook from wp-cli
					sed 's/[+|-]//g' $coreFile > $trshFile && mv $trshFile $coreFile;
					# This is the old method, for some reason is stopped working
					#awk 'FNR == 1 {next} {print $1}' $coreFile > $trshFile && mv $trshFile $coreFile;
					# This seems to be working better, for now
					cat $coreFile | awk 'FNR == 1 {next} {print $1}' > $trshFile && mv $trshFile $coreFile;
					# Just in case, try to remove all blank lines. DOS formatting is messing up output with PHP crap
					sed '/^\s*$/d' $coreFile > $trshFile && mv $trshFile $coreFile;
					# Remove line breaks, value should noe equal 'version x.x.x' or some such.
					sed ':a;N;$!ba;s/\n/ /g' $coreFile > $trshFile && mv $trshFile $coreFile;
					# So much sed, so little time
					#sed -n -E -e '/version/,$ p' $coreFile > $trshFile && mv $trshFile $coreFile;
					COREUPD=$(<$coreFile)

					# Update available!  \o/
					echo -e "";

					# Check for broken WP-CLI garbage
					if [[ $COREUPD == *"PHP"* ]]; then
  						warning "Checking for available core update was unreliable, skipping.";
					else

						if  [ "$FORCE" = "1" ] || yesno --default no "A new version of Wordpress is available ("$COREUPD"), update? [y/N] "; then
							cd $WORKPATH/$APP/public; \
							if [ "${QUIET}" != "1" ]; then
								$WPCLI/wp core update --no-color &>> $logFile &
								spinner $!
							else
								$WPCLI/wp core update --no-color &>> $logFile
							fi

							# Double check upgrade was successfull if we still see 'version' 
							# in the output, we must have missed the upgrade somehow
							$WPCLI/wp core check-update --quiet --no-color &> $trshFile
							if grep -q "version" $trshFile; then
								error "Core update failed.";
							else
								sleep 1
								cd $WORKPATH/$APP/; # \	
								info "Wordpress core updates complete."; UPDCORE=1
							fi
							
							# Update staging server database if needed
							if [ "$UPDCORE" = "1" ]; then
								info "Upgrading development database..."; lynx -dump $DEVURL/system/wp-admin/upgrade.php > $trshFile
							fi							
						else
							info "Skipping Wordpress core updates..."
						fi
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
	fi
}

function wpCheck() {
	# Wordfence is really pissing me off now
	if [[ "${WFCHECK}" == "TRUE" ]]; then
		# For the logfile
		sudo -u "apache" -- $WPCLI/wp plugin status --no-color &>> $logFile
		# For the console/smart commit message
		sudo -u "apache" -- $WPCLI/wp plugin update --dry-run --no-color --all &> $wpFile
	else
		# For the logfile
		$WPCLI/wp plugin status --no-color &>> $logFile
		# For the console/smart commit message
		$WPCLI/wp plugin update --dry-run --no-color --all &> $wpFile
	fi

	# Other options, thanks Corey
	# wp plugin list --format=csv --all --fields=name,update_version,update | grep 'available'
	# wp plugin list --format=csv --all --fields=title,update_version,update | grep 'available'
}
