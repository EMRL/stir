#!/bin/bash
#
# Here are examples of settings you might need to change on a per-project 
# basis. This file should be placed in config/deploy.sh in your projects' 
# root folder. Project settings will override both system & per-user settings.
# 
# If any value set here will override both global and per-user settings.

# The URL for this repo's hosting, with no trailing slash. For example, if 
# you use Github and your repo URL looks like https://github.com/EMRL/deploy
# your REPOHOST should be set to https://github.com/EMRL (with no trailing slash)
# If most of your repos are all hosted at the same location, you may want to define
# this in either the global or user configuration files.
# REPOHOST=""

# If you have no SSH key or wish to login manually using your account name and
# password in the console, set NOKEY to exactly "TRUE"
# NOKEY="TRUE"

# A human readable project name
# PROJNAME="Best Webapp Ever"	

# A human readable client name
# PROJCLIENT="Client Name"

# Development project URL, including http:// or https:// 
# DEVURL="http://devurl.com"

# Production, or "Live" project URL, including http:// or https://
# PRODURL="http://productionurl.com"

# The exact name of the Bitbucket/Github repository
# REPO="name-of-repo"

# Advanced Custom Fields Pro License
#
# Too many issues seem to crop up with the normal method of updating the Wordpress 
# plugin Advanced Custom Fields Pro. Including your license key below will enable 
# upgrades to happen more reliably.
# ACFKEY="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

# Configure your branches. In most cases the name will be master & production. If
# you are only using a master branch, leave production undefined.
# MASTER="master"
# PRODUCTION="production"

# Configure merge behavior. If you wish to automatically merge your MASTER and 
# PRODUCTION branches when deploying, set AUTOMERGE to TRUE.
# AUTOMERGE="TRUE"

# Define CHECKBRANCH if you only want deploy to run when the set branch is 
# currently checked out; e.g. if CHECKBRANCH="master" and the current branch is 
# "production", deployment will halt.
# CHECKBRANCH="master"

# If for some reason you'd like a default commit message. It will
# always be editable before finalizing commit.	
# COMMITMSG="This is a default commit message"

# The command to finalize deployment of your project(s)
# DEPLOY="mina deploy"				

# Set the address and subject line of 
# TO="deploy@emrl.com"

# Disallow deployment; set to TRUE to enable. Double negative, it's tricky.
# DONOTDEPLOY="TRUE"	

# Integration ID
#
# This is used to post deploy logs to project management systems that can 
# external email input. For examples, for our task management system 
# accepts emails in the format task-####@projects.emrl.com, with the #### 
# being the task identification number for the project being deployed.
# TASK="task"

# Slack Integration
# 
# You'll need to set up an "Incoming Webhook" custom integration on the Slack 
# side to get this ready to roll. 
# See https://YOURTEAMNAME.slack.com/apps/manage/custom-integrations to get 
# going. Once your Slack webhook is setup, run # 'deploy --slack-test' to 
# test your configuration.
#
# Set POSTTOSLACK to "TRUE" to enable Slack integration.
# POSTTOSLACK="TRUE"

# Add your full Webhook URL below, including https://
# SLACKURL="https://hooks.slack.com/services/###################/########################"

# Normally only successful deployments are posted to Slack.
# Enable the settings below to post on WARNiNG and/or ERROR.
# SLACKERROR="FALSE"

# Post commit logs to this URL.
# POSTURL=""
