#!/bin/bash
#
# deploy.sh
#
# Project-specific settings
#
#
#
# The command to finalize deployment of your project(s)
# DEPLOY="mina deploy"				

# Activate "Smart Commits"; this feature tries to create automatic 
# commit messages by parsing the log files generated during 
# Wordpress updates. Set to exactly "1" to activate.
# SMRTCOMMIT="1"					

# Send log file in HTML?
# LOGHTML="0"

# Strips the bulk of nasty PHP debug messages out of the 
# log files that are emailed unpon deployment.
# NOPHP="1" 

# Activate Permission Fix. With multi-user stuff going on, sometimes
# permission problems may arise. This function will reset permissions
# upon each deploy. Set PERMFIX to exactly "1" to activate.
# PERMFIX=""
# DEVUSER="cworrell"				# Lead developer username
# DEVGROUP="web"					# Lead developer group
# APACHEUSER="apache"				# Apache user
# APACHEGROUP="apache"				# Apache group

# Set the address and subject line of 
# TO="deploy@emrl.com"		

# Here are examples of settings you might need to change on 
# a per-project basis. If so, create a file in your projects' root 
# folder called .deployrc. Project settings will override both 
# system & per-user settings.

# A human readable project name
#PROJNAME="Best Webapp Ever"	

# A human readable client name
#PROJCLIENT="Best Client Ever"

# Development project URL, without http://
# DEVURL=""

# Production, or "Live" project URL, without http://
# PRODURL=""

# If for some reason you'd like a default commit message. It will
# always be editable before finalizing commit.	
#COMMITMSG="This is a default commit message"

# Disallow deployment	
#DONOTDEPLOY="1"	

# Integration options.			
# 
# Set values for where you'd like to post commit messages to 
# via email. You can use something like Zapier to re-post that
# to whatever service you like, or if your project tracker allows
# for input directly via email like ours does, you post directly.
# Some of these options will definitely need to be set in the 
# project's .deployrc, not in a master configuration.

# Email from domain. Whatever you're integrating with may need
# a different From: address than that of the the machine you're 
# actually deploying from.
# FROMDOMAIN="emrl.com"

# If you need to specify a user, other than your unix user name
# to be the in the From: email, do it here. Otherwise Leave blank.
# FROMUSER=""

# Post commit logs to this email address. This should probably 
# be set per-project. For examples, for otask management system,
# this email would be task-####@projects.emrl.com, with ####
# being the task number for the project being deployed.
# POSTEMAILHEAD="task-"
# POSTEMAILTAIL="@projects.emrl.com"
# Post commit logs to this URL 
# POSTURL=""