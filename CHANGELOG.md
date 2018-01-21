# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]
### Changed
- Configuration files restructred for better readability 
- Many function and variable names changed for better consistency
### Fixed
- Google analytics no longer incorrectly display for projects that do not use them 

## [3.6.6] - 01-13-2018
### Added
- Server health information now included in email/html logs via integration with [PHP Server Monitor](http://www.phpservermonitor.org/) using this [API](https://github.com/skydiver/PHP-Server-Monitor-API)
- Option to include web hosting as a line item on monthly reports
- Remote servers can now host project logs, digests, statistics, and reports
- New release check now runs upon launch
### Changed
- Item descriptions are now editable in reports 
- Cleaned up email output generated using `deploy --email-test`
- Report URLs are now writted as `report/YEAR-MONTH.php` instead of using a hard to remember string
### Fixed 
- Fixed a bug with running a report on dates in the previous calendar year
- Added a workaround for Google potentially displaying over 100% of user sessions as new
- Fixed a bug that kept SSH keys from being properly checked 

## [3.6.5] - 11-17-2017
### Added
- Monthly reports can now be generated using `deploy --report [project name]`
- Project configuration files can be named either `deploy.sh` or `.deploy.sh`
- New configuration switch `INCOGNITO` strips emails and file paths from verbose output and log files for greater security
- Added Webhook integration for SMS digests using [Zapier](https://zapier.com/zapbook/sms/webhook/)
- Deployments that fail on push can now be repaired using 'deploy --repair'
### Fixed
- Links to Github commits now use the correct URL
- Using `bundle` in deployment command should now pass checks more accurately
- Poor analytics results are now correctly filtered from digests

## [3.6.4] - 09-14-2017
### Added
- Added `--update-only` switch, allowing for the deployment of only Wordpress plugin/core updates, while skipping over local code changes
- Added option for email notification to be sent "clean," without full logging information
- Added a default check for a configuration file (`deploy.sh`) in project root directory
- HTML theme colors can be configured in `[theme root]/theme.conf`
- Added error handling for projects with no commits
### Changed
- Recently changed files that are .gitignored will no longer halt automated deployment
- Running as root is no longer allowed; this can be overridden by setting `ALLOWROOT="TRUE"`
- Slightly improved deployment error checking
- Tightened up many functions
### Fixed
- All HTML email variables are now correctly validated and post-processed
- Digests no longer post to Slack when there's been no activity

## [3.6] - 07-08-2017
### Added
- Added experimental approval/denial code queue functions
- Added ssh key checking when required, upon starting each deployment session
- Added ssh configuration check when deploying to live environments via `mina`
- Added integration with `gitchart` for generation of graphic statistics
- Added integration with Google Analytics for web projects
- Added Wordpress database checks
- Added another failsafe check; `deploy --automate` will not deploy unless repo is on master branch
- Added `--time` switch to allowing tracking work time when deploying manually
- Added project information to test emails sent with the `--email-test` switch
- Added `deploy --unlock` to make it easier remove stale .lock files
- Added options to define custom file paths used in your Wordpress projects
- Added email and Slack notification for automated deployments when no updates are available
- Added email integration test
- Added the ability to disable Wordpress core updates for sites that require it
### Changed
- Improved rendering of emails in Windows 10 Mail client
- Brought back client emails in the form of a weekly digest
- When deploying using the `--current` directory; instead of app directory name, the actual repo name will be used to identify the project in Slack and email notifications
- Improved readability of full logs
- Improved language for consistency in some functions
### Fixed
- Fixed a rare bug with saving HTML logs
- Fixed a visual bug that displayed incorrect branch names to the user 
- Missing client logos no longer break HTML emails and logs
- Fixed a bug with Slack not including commit messages when using `deploy --automate`

## [3.5.7] - 03-03-2017
### Added
- Added the ability to add time to task management system worklogs via email integration
- Added `deploy --publish` for deploying current production code to live environment
### Changed
- Updated default HTML theme
- Logged output is now time stamped
- Rewrote Slack integration
- Improved log details
### Fixed
- Fixed issues with HTML log on mobile devices
- Fixed a bug with restoring previously checked out branch
- Fixed a bug in which an Advanced Custom Fields Pro update could create an empty smart commit message

## [3.5.5] - 02-12-2017
### Added
- Added `--no-check` switch to override active file and server checks
- Added the option to stash dirty files during unsupervised deployment of Wordpress updates
- Added configurable From: email address for log files
### Changed
- Upon exit, deploy will now return the repo's current active branch to its original state, instead of assuming checkout of master
- Improved dependency checks
- Emails are now sent using Sendmail
- When run as a cron (`--automate`) integration emails are now sent from the default email address, not the spoofed user's email
- Slack webhook URL is no longer displayed in logs
### Fixed
- Fixed a bug with text-format emails not including complete logs
- Fixed issue with passing user variable to Slack integration when an error is triggered
- Fixed output from `deploy --function-list` and `deploy --variable-list [project]`
- Fixed missing path variable that kept `deploy --automate` from running correctly

## [3.5] - 11-11-2016
### Added
- Added `deploy --automate` for scheduled update deployments. Equivalent to `deploy --force --update --quiet` with the addition of a flag to enable sending a scheduled update email notice to clients
- Added ability to save HTML logs to local filesystem
- Added ability to post log files to a remote host with scp
- Added option to delete log files after a certain amount of days
- Added HTML email log option, with custom templates assignable either globally or by project
- Added link to detailed log files from Slack messages
- Added more robust branch checking
- Added option to enforce server check
### Changed
- Recently changed file checks are now more accurate
- Logs are now only emailed and posted when something noteworthy has occured - e.g. a commit has been made or an error has occurred
- Changed checkout behavior - master branch is now only checked out when needed
- Cleaned up log output
- Changed default merge behavior - deploy will no longer perform automatic merges unless ran as `deploy --merge` or `AUTOMERGE="TRUE"` is defined in `config/deploy.sh`
- Existence of all defined branches is now confirmed before starting deployment process
### Fixed 
- Fixed a small bug when repo name is undeclared when not running `deploy --current`

## [3.4] - 07-07-2016
### Added
- Added a more reliable method of updating Advanced Custom Fields Pro
- Added "Garbage Collection" mode to help keep your repo neat and tidy
- Added optional fix for Wordfence firewall permission problems
- Added check for .git/index permission issues
### Fixed
- Fixed some issues that can cause permission problems in certain environments

## [3.3.4] - 05-16-2016
### Added
- Added [Travis CI](https://travis-ci.org/EMRL/deploy) tests
- Added `deploy --function-list` to list all available functions() for help debugging with in the future
### Changed
- Cleaned up many functions
- Cleaned up configuration files
- Exit codes now pass more reliably to Slack messages 
### Fixed
- Fixed issue with pkgDeploy() not executing deployment command correctly

## [3.3.3] - 02-11-2016
### Added
- Added active file check as another failsafe when running as cron (`deploy --force --update --quiet`) to stop potential issues that may come up in multi-developer environments
- Added a new option to include error messages in Slack integration
- Option added to projects' `config/deploy.sh` to enforce repo to have a certain branch checked out before beginning deployment session. 
- Added `deploy --slack-test` to allow testing of Slack integration
- Added change log
### Changed
- Running `deploy --current` will now deploy the current directory and no longer needs to be launched as `deploy --current [project name]`

## [3.3] - 02-03-2016
### Added
- Added ssh key detection, allows manual login to repo host if keys not found
- Added Slack integration
- Added `deploy --force --update --quiet` for unattended Wordpress plugin/core updates via cron scheduling 
- Added `deploy --current` which will allow for deployment of current working directory if a project is found
- Added `deploy --skip-update`

## [3.1] - 11-12-2015
### Added
- Added install script
- Added progress indicators
- Implemented logging
- Added "Smart Commits" - commit messages are generated automatically based on Wordpress core/plugin updates that have occured
### Changed
- Increased detail of verbose output
- Configuration files for both the user, and the project are now automatically created if not found 

## [3.0] - 10-21-2015
### Added
- Basic `wp-cli` integration  
### Changed
- Old monolithic script rewritten


[Unreleased]: https://github.com/EMRL/deploy/compare/v3.6.6...HEAD
[3.6.8]: https://github.com/EMRL/deploy/compare/v3.6.7...3.6.8
[3.6.7]: https://github.com/EMRL/deploy/compare/v3.6.6...3.6.7
[3.6.6]: https://github.com/EMRL/deploy/compare/v3.6.5...3.6.6
[3.6.5]: https://github.com/EMRL/deploy/compare/v3.6.4...3.6.5
[3.6.4]: https://github.com/EMRL/deploy/compare/v3.6...v3.6.4
[3.6]: https://github.com/EMRL/deploy/compare/v3.5.7...v3.6
[3.5.7]: https://github.com/EMRL/deploy/compare/v3.5.5...v3.5.7
[3.5.5]: https://github.com/EMRL/deploy/compare/v3.5...v3.5.5
[3.5]: https://github.com/EMRL/deploy/compare/v3.4...v3.5
[3.4]: https://github.com/EMRL/deploy/compare/v3.3.4...v3.4
[3.3.4]: https://github.com/EMRL/deploy/compare/v3.3.3...v3.3.4
[3.3.3]: https://github.com/EMRL/deploy/compare/v3.3...v3.3.3
[3.3]: https://github.com/EMRL/deploy/compare/v3.1...v3.3
[3.1]: https://github.com/EMRL/deploy/compare/v3.0...v3.1
[3.0]: https://github.com/EMRL/deploy/commits/v3.0
