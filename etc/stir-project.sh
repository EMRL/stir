#!/usr/bin/env bash
#
#
# Here are examples of settings you might need to change on a per-project
# basis. This file should be placed in either the project's root folder,
# or in /config/. Settings configured in this file will override both
# system & user settings.

# This value indicates the version number when this file was last changed:
# it does not necessarily reflect stir's current version number.
# DO NOT EDIT THIS NUMBER OR YOU MAY BLOW SOMETHING UP
PROJECT_VERSION="3.8.5.4"


###############################################################################
# Project Information
###############################################################################

# A human readable project name
# PROJECT_NAME="{{PROJECT_NAME}}"

# A human readable client name
# PROJECT_CLIENT="{{PROJECT_CLIENT}}"

# Staging URL, including http:// or https://
# DEV_URL="{{DEV_URL}}"

# Production, or "Live" project URL, including http:// or https://
# PROD_URL="{{PROD_URL}}"


###############################################################################
# Git Configuration
###############################################################################

# If you will need to execute custom scripts before beginning your session,
# insert the command with full path in the value below. If you won't be
# needing to run prepare scripts, leave this value empty or set to FALSE. To
# use stir's built-in Wordpress prepare function, set this value to TRUE.
# PREPARE="{{PREPARE}}"

# To reset projects files before executing your prepare sequence, set the
# value below to TRUE.
# PREPARE_WITH_RESET="{{PREPARE_WITH_RESET}}"

# If you need to load extra environment variables, enter the location to
# that file below.
# PREPARE_CONFIG="{{PREPARE_CONFIG}}"

# The URL for this repo's hosting, with no trailing slash. For example, if
# you use Github and your repo URL looks like https://github.com/EMRL/deploy
# your REPO_HOST should be set to https://github.com/EMRL (with no trailing
# slash) If most of your repos are all hosted at the same location, you may
# want to define this in either the global or user configuration files. Note
# that Github will currently ask for a user/password in when using https://
# instead of ssh - a fix for this is incoming ASAP.
# REPO_HOST="{{REPO_HOST}}"

# The exact name of the Bitbucket/Github repository
# REPO="{{REPO}}"

# Configure your branches. In most cases the name will be `master` or `main`,
# and production. If you are using a `staging` branch you can declare that 
# here as well If you are only using a master branch, leave the others 
# undefined.
# MASTER="{{MASTER}}"
# STAGING="{{STAGING}}"
# PRODUCTION="{{PRODUCTION}}"

# Configure merge behavior. If you wish to automatically merge your branches
# when deploying, set AUTOMERGE to TRUE.
# AUTOMERGE="{{AUTOMERGE}}"

# If dirty (yet to be committed) files exist in the repo, stir will normally
# not halt execution when running with the --automate flag. If you prefer to
# have the dirty files stashed and proceed with updates set the below value
# to TRUE. Files will be unstashed after the deployment is complete.
# STASH="{{STASH}}"

# Define CHECK_BRANCH if you only want stir to run when the set branch is
# currently checked out; e.g. if CHECK_BRANCH="master" and the current branch is
# "production", deployment will halt.
# CHECK_BRANCH="{{CHECK_BRANCH}}"

# If you have no SSH key or wish to login manually using your account name and
# password in the console, set NO_KEY to exactly "TRUE"
#
# NO_KEY="{{NO_KEY}}"

# By default stir will check for valid SSH keys; if you want to override this
# behavior, set DISABLE_SSH_CHECK to TRUE
# DISABLE_SSH_CHECK="{{DISABLE_SSH_CHECK}}"


###############################################################################
# Wordpress Setup
###############################################################################

# Some developers employ a file structure that separates Wordpress core from
# their application code. If you're using non-standard file paths, define the
# root, system, and app (plugin/theme) directories below. Note that the forward
# slash is required. Just about everyone on the planet can leave this alone.
# WP_ROOT="{{WP_ROOT}}"
# WP_APP="{{WP_APP}}"
# WP_SYSTEM="{{WP_SYSTEM}}"

# If this Wordpress project requires a specific version of PHP that is not 
# your machine's default version, set the path to those commands below
# Example: WP_CLI_PATH="/usr/bin/php74 ~/bin/wp"
# WP_CLI_PATH="{{WP_CLI_PATH}}"
# COMPOSER_CLI_PATH="{{COMPOSER_CLI_PATH}}"

# If you do not want to allow core updates, set DO_NOT_UPDATE_WP to TRUE. This
# does not currently disable composer updating core.
# DO_NOT_UPDATE_WP="{{DO_NOT_UPDATE_WP}}"

# Advanced Custom Fields Pro License
#
# When not updated via composer, many issues seem to crop up with updating the 
# Wordpress plugin ACF Pro. We recommend using composer for updates and setting
# the value below to TRUE
# ACF_COMPOSER="{{ACF_COMPOSER}}"

# Including your ACF license key below will enable upgrades to happen more 
# reliably.
# ACF_KEY="{{ACF_KEY}}"
#
# If you need to lock your version of ACF fro some reason, set the value
# below to TRUE
# ACF_LOCK="{{ACF_LOCK}}"

# Gravityforms License
# GRAVITY_FORMS_LICENSE="{{GRAVITY_FORMS_LICENSE}}"


###############################################################################
# Deployment Configuration
###############################################################################

# The command to finalize deployment of your project(s); set DEPLOY="SCP" to
# use the built-in scp deployment method.
# DEPLOY="{{DEPLOY}}"

# Disallow deployment; set to TRUE to enable. Double negative, it's tricky.
# DO_NOT_DEPLOY="{{DO_NOT_DEPLOY}}"

# SCP Deployment
# --------------

# Staging file path to copy to production host, relative to the project's root
# directory (forward slash required)
# STAGING_DEPLOY_PATH="{{STAGING_DEPLOY_PATH}}"

# Production host info
# PRODUCTION_DEPLOY_HOST="{{PRODUCTION_DEPLOY_HOST}}"

# Full path path to copy files to on production server
# PRODUCTION_DEPLOY_PATH="{{PRODUCTION_DEPLOY_PATH}}"

# Deployement user info
# SCP_DEPLOY_USER="{{SCP_DEPLOY_USER}}"

# DANGER DANGER: If for some reason you absolutely can't use an SSH key you
# can configure the path to a text file containing *only* your password.
# SCP_DEPLOY_PASS="{{SCP_DEPLOY_PASS}}"

# Set your port number if using a port other than the standard 22
# SCP_DEPLOY_PORT="{{SCP_DEPLOY_PORT}}"


###############################################################################
# Notifications
###############################################################################

# Project Management
# ------------------

# Task#: This is used to post logs to project management systems
# that can accept external email input. For examples, our task management
# system accepts emails in the format task-####@projects.emrl.com, with
# the #### being the task identification number for the project being deployed.
# TASK="{{TASK}}"

# If you wish to have automated deployments add tracked time to your project
# management system, uncomment and configure the two values below. TASK_USER
# should be the email address of the user that the time will be logged as,
# and ADD_TIME is the amount of time to be added for each deployment. Time
# formats can in hh:mm (02:23) or HhMm (2h23m) format.
# TASK_USER="{{TASK_USER}}"
# ADD_TIME="{{ADD_TIME}}"

# Slack
# -----

# You'll need to set up an "Incoming Webhook" custom integration on the Slack
# side to get this ready to roll.
# See https://YOURTEAMNAME.slack.com/apps/manage/custom-integrations to get
# going. Once your Slack webhook is setup, run # 'stir --test-slack' to
# test your configuration.

# Set POST_TO_SLACK to "TRUE" to enable Slack integration.
# POST_TO_SLACK="{{POST_TO_SLACK}}"

# Add your full Webhook URL below, including https://
# SLACK_URL="{{SLACK_URL}}"

# Normally only successful deployments are posted to Slack.
# Enable the settings below to post on WARNiNG and/or ERROR.
# SLACK_ERROR="{{SLACK_ERROR}}"

# If you'd like to post a Slack notification with a URL to view the weekly
# digest set the following to TRUE. If you want to use an incoming webhook
# other than the one defined in SLACK_URL, enter that here *instead* of TRUE.
# DIGEST_SLACK="{{DIGEST_SLACK}}"

# Webhooks
# --------
# Post event notifications to this URL.
# POST_URL="{{POST_URL}}"


###############################################################################
# Logging
###############################################################################

# If you need to send log_files and email alerts to address(es) other than those
# you may have configured globally, enter them below.
# TO="{{TO}}"

# If you want to use an email template unique to this project (instead of the
# globally configured template) define it below. HTML templates are stored in
# separate folders in /etc/stir/html. The value used below should be the
# folder name of your template.
# HTML_TEMPLATE="{{HTML_TEMPLATE}}"

# If you are using html log_files, define the full URL to the client's logo
# CLIENT_LOGO="{{CLIENT_LOGO}}"

# If you are using a digest theme that includes a cover image, at the URL below.
# COVER="{{COVER}}"

# IF INCOGNITO is set to true, log files as well as verbose output to screen
# will be stripped of details such as email addresses and system file paths.
# INCOGNITO="{{INCOGNITO}}"

# Post HTML logs to remote server. This needs to be set to "TRUE" even you
# are only posting to LOCALHOST.
# REMOTE_LOG="{{REMOTE_LOG}}"

# Define the root url where the stir log will be accessible with no
# trailing slash
# REMOTE_URL="{{REMOTE_URL}}"

# If using HTML logs, define which template you'd like to use. HTML templates
# are stored in separate folders in /etc/stir/html. The value used below
# should be the folder name of your template.
# REMOTE_TEMPLATE="{{REMOTE_TEMPLATE}}"

# Post logs via SCP
# SCP_POST="{{SCP_POST}}"
# SCP_USER="{{SCP_USER}}"
# SCP_HOST="{{SCP_HOST}}"
# SCP_HOST_PATH="{{SCP_HOST_PATH}}"
# SCP_PORT="{{SCP_PORT}}"

# DANGER DANGER: If for some reason you absolutely can't use an SSH key you
# can configure the path to a text file containing *only* your password.
# SCP_PASS="{{SCP_PASS}}"

# If you're posting logs to a place on the same machine you're deploying from,
# set POSTTOLOCALHOST to "TRUE" and define the path where you want to store
# the HTML logs.
# POST_TO_LOCAL_HOST="{{POST_TO_LOCAL_HOST}}"
# LOCAL_HOST_PATH="{{LOCAL_HOST_PATH}}"


###############################################################################
# Digest Emails
###############################################################################

# If you'd like to send branded HTML emails using the `stir --digest [project]`
# command, enter the recipient's email address below. Email value can be a
# comma separated string of multiple addresses.
# DIGEST_EMAIL="{{DIGEST_EMAIL}}"

# To include your website's RSS feed in your digest emails, set your feed's 
# URL below.
# NEWS_URL="{{NEWS_URL}}"

# To include a detailed breakdown of some select traffic, AdWords, and 
# ecommerce analytics, set to TRUE
# INCLUDE_DETAILS="{{INCLUDE_DETAILS}}"


###############################################################################
# Monthly Reporting
###############################################################################

# First and last name of the primary contact for this client
# CLIENT_CONTACT="{{CLIENT_CONTACT}}"

# Include hosting as a line item on monthly reports? If set to TRUE, the report
# line item will read "Monthly web hosting"; customize the text included in
# report by setting it to any other value.
# INCLUDE_HOSTING="{{INCLUDE_HOSTING}}"


###############################################################################
# Work Logs
###############################################################################

# EXPERIMENTAL - Ingest work logs from Chrono (or any RSS feed) for display in
# the statistics dashboard

# Set the URL of your RSS work log. Feed will be parsed and formatted into html
# via feed.emrl.co
# RSS_URL="{{RSS_URL}}"


###############################################################################
# Invoice Ninja project integration
###############################################################################

# Client ID number
# IN_CLIENT_ID="{{IN_CLIENT_ID}}"

# Default product code
# IN_PRODUCT="{{IN_PRODUCT}}"

# Default item cost
# IN_ITEM_COST="{{IN_ITEM_COST}}"

# Default item quantity
# IN_ITEM_QTY="{{IN_ITEM_QTY}}"

# Default item notes
# IN_NOTES="{{IN_NOTES}}"

# Set to TRUE if invoices should be immediately be emailed upon creation
# IN_EMAIL="{{IN_EMAIL}}"

# Include monthly commit report
# IN_INCLUDE_REPORT="{{IN_INCLUDE_REPORT}}"


###############################################################################
# Google Analytics
###############################################################################

# API credentials
# CLIENT_ID="{{CLIENT_ID}}"
# CLIENT_SECRET="{{CLIENT_SECRET}}"
# REDIRECT_URI="{{REDIRECT_URI}}"

# OAuth authorization will expire after one hour, but will be updated when needed
# if the tokens below are configured correctly
# AUTHORIZATION_CODE="{{AUTHORIZATION_CODE}}"

# Tokens
# ACCESS_TOKEN="{{ACCESS_TOKEN}}"
# REFRESH_TOKEN="{{REFRESH_TOKEN}}"

# Google Analytics ID
# PROFILE_ID="{{PROFILE_ID}}"


###############################################################################
# Server Monitoring
###############################################################################

# Uptime and average latency can be included in logs, digests, and reports when
# integrating with PHP Server Monitor, and an add-on API.
# See https://github.com/EMRL/stir/wiki/Integration for more information.

# Full API URL
# MONITOR_URL="{{MONITOR_URL}}"

# Email/password of the user that will access the API. Password can be stored in
# a file outside of the project repo for security reasons
# MONITOR_USER="{{MONITOR_USER}}"
# MONITOR_PASS="{{MONITOR_PASS}}"

# Server ID to monitor. When viewing the server on your web console, your URL
# will be something like https://monitor.com/?&mod=server&action=view&id=3 - in
# this case SERVER_ID would be "3" (notice the &id=3 at the end of the URL)
# SERVER_ID="{{SERVER_ID}}"


###############################################################################
# Dropbox integration
###############################################################################

# Define the *full* path to this project's backup. Do not including "/Home" as
# part of the path
# DB_BACKUP_PATH="{{DB_BACKUP_PATH}}"


###############################################################################
# Mautic integration
###############################################################################

# Your Mautic instance's root url. Make sure you've enabled both API and 
# BasicAuthentication in your Mautic's configuration, and the API tab
# MAUTIC_URL="{{MAUTIC_URL}}"

# Your authorization key. Generate your key by running
# "echo -n "user:pass" | base64"
# at your schell prompt
# MAUTIC_AUTH={{MAUTIC_AUTH}}

# Mautic changed its JSON payload format in version 3+. If you're using an 
# older version of Mautic (v1 or v2) then set the following to TRUE
# MAUTIC_LEGACY_VERSION="{{MAUTIC_LEGACY_VERSION}}"


###############################################################################
# Malware scanning
###############################################################################

# If you want to make use of nikto for malware/security host scanning, define
# its full path (including command) as well as its configuration file below
# NIKTO="{{NIKTO}}"
# NIKTO_CONFIG="{{NIKTO_CONFIG}}"
# NIKTO_PROXY="{{NIKTO_PROXY}}"
