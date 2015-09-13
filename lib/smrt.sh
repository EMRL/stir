#!/bin/bash
#
# smrtCommit()
#
# Tries to create "Smart Commit" messages based on parsing
# output from wp-cli.
trace "Loading smrtCommit()"

# Constructing smart *cough* commit messages
function smrtCommit() {
	if [[ $SMARTCOMMIT == "TRUE" ]]; then
		trace "Building commit message"

		# Checks for the existence of a successful plugin upgrade, using grep, and if 
		# we find updates, grab the relevant line of text from the logs
		PCA=$(grep '\<Success: Updated' $logFile | grep 'plugins')
		if [[ -z "$PCA" ]]; then
			trace "No plugin updates"
		else
			# How many plugins we updated? First, strip out the Success:
			PCB=$(echo $PCA | sed 's/^.*\(Updated.*\)/\1/g')
			# Strips the last period, makes my head hurt.
			# PCC=${PCB%?}; PCD=$(echo $PCB | cut -c 1-$(expr `echo "$PCC" | wc -c` - 2))
			PCC=$(echo $PCB | tr -d .)
			# Get this thing ready.
			# Remove the leading spaces 
			# awk '{print $1}' $wpFile > $trshFile && mv $trshFile $wpFile;
			# Add commas between the plugins with this
			#sed 'N;s/\n/, /' $wpFile > $trshFile && mv $trshFile $wpFile;
			trace "Plugin status ["$PCD"]"
			# Replace current commit message with Plugin upgrade info 
			COMMITMSG=$PCC
			# Will have to add the stuff for core upgrade, still need logs
			#
		fi
	fi
}