# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]
### Added
- Settings use specific versions of PHP with `composer` and `wp-cli` are now available, per project
- ACF Pro can now be updated via `composer` as well as the legacy method
- Added `--skip-git` for projects that are focused only on client communication
- Added ability to turn off RSS feed per project, even if set globally
- Added ability to define which Wordpress plugins are to be activated when using `--prepare-with-reset` and when running updates on a Wordpress project

### Fixed
- Fixed success color rendering in default html theme
- Fixed a bug in preparing new Wordpress projects
- Fixed an activity log email formatting error
- Resolved [#189](https://github.com/emrl/stir/issues/189)
- Updating Wordpress core should now be more reliable 
- Gravatars are now being accessed securely

## [3.8.5]
### Added
- Added Mautic integration for reporting on marketing email performance
### Changed
- Some variable names in configuration files have changed, and require a new migration process which is described in detail during the update process
- Removed the ability to set a default commit message
- Improved Wordpress core and plugin update functions
- Improved install process
### Fixed
- Smart Commits include Wordpress core updates once again (#151)
- Fixed a bug that prevented the sending of email in some environments (#193)

## [3.8.4] - 2-14-2021
### Fixed 
- Updates to Wordpress production databases should now only happen when actually needed
- Fixed issues generating monthly reports

## [3.8.3] - 11-12-2020
### Added
- If there are analytics to report, digest emails will now be sent even if there are no code updates to report
- Monthly PDF format reports can now be attached to invoices when using the `--invoice` switch
### Fixed
- Cleaned up some reposnsive layout issues with digests
- Avg. session duration is displayed correctly in digests

## [3.8.2] - 10-17-2020
### Added
- Digests can now display detailed traffic, Goodle Ads, and ecommerce activity data 
### Changed
- Engagement reports and digests now use the more useful `pageviews` instead of `hits`
- Variables changed to use more consistent naming 
### Fixed
- Internal command variables are now correctly initialized

## [3.8] - 7-13-2020
### Added
- Notification emails can now be sent using external SMTP servers   
- Launching `stir` using the `--prepare-with-reset` will completely delete and reset the local copy of the target project, and then launch your defined prepare action
- The number of days of engagement data to be displayed can now be configured in the projects' `theme.conf` 
- Project settings can be displayed in an easy to read format using the `show-settings` switch
- Added a simple external script for perfoming batch stir actions, see `etc/extras/bulk.stir.sh`
- Global project directory and repo host variables are now set during the initial install process
- Project settings are now backed up when performing a `--reset` when a global `CONFIG_BACKUP` is declared
- Added `--update-acf` to account for unreliable update checks
- Added `--debug-to-file` allowing for very verbose logs to be saved to file called `debug.log` in your current working directory 
- New releases of `stir` will now update "in place"
- `--skip-updates` now aliases to `--skip-updated` because I kept forgetting the switch name
- Added a workaround for emailing Invoice Ninja invoices with an offset invoice numbering
### Changed
- Deprecated and removed the `gitStatus()`, `gitStart()`, `permFix()` and `fix_index()` functions
- Deprecated the `WP_CLI` and `MAILPATH` global variables
- Deprecated approval functionality
- Plugins are no longer activated by default, unless required for reliable upgrades
- Composer now creates less noise in log_files
- Improved dependency checks
- Improved temporary file management
- Improved first-run install process
### Fixed
- Binary files should no longer confuse log parsing functions
- Missing project configuration error now exits more gracefully
- Environment checking works more reliably
- Analytics functions changed to accept more variation in payloads received from Google
- Checking for new `stir` releases works more reliably
- Fixed a small email text bug
- Commit authors with no Gravatar image are now correctly given the default profile image
- Fixed a layout bug in the default HTML email footer

## [3.7.4] - 11-18-2019
### Added
- Automated Worpdress updates may now made by cloning a temporary copy of the project's repo, running the updates, and destroying upon completion
- Origin sync is now forced when running using `--automate`
- Prepare hook added
- Added `--reset` switch
- Default HTML theme now includes a dark mode
### Changed
- `deploy` is now `stir`
- Invoice creation will now exit gracefully if project is not correctly configured
- Initial project preparation and cloning has been simplified
- Improved accuracy of smart commit messages
- Approval queue functions are now deprecated and slated for removal
### Fixed
- Production URL must now be defined before malware scans are attempted 
- Fixed many small bugs

## [3.7.3] - 03-12-2019
### Added
- Wordpress projects can now be managed using either `composer` or `wp-cli` (or both) transparently
- ACF Pro update files must now pass an integrity check before proceeding with plugin upgrade
### Changed
- Project deployment can be disabled by adding a file called `.donotdeploy` in the project's root directory (This is the equivalent of setting `DO_NOT_DEPLOY="TRUE"` in `.deploy.sh`)
### Fixed
- Fixed a bug that occasionally caused successful deployment to be incorrectly reported

## [3.7.2] - 09-25-2018
### Added
- Project dashboards have been redesigned to include more analytics charts and information
- Digest emails can now include a chart showing the week's analytics
### Changed 
- Improved HTML post-processing
### Fixed
- The `--stats` flag should no longer cause issues when being properly run from a cron process
- Log files should no longer be left behind in the `/tmp` directory
- Fixed a problem where statistic dashboard could get corrupted when multiple instances of `deploy --stats` are running
- Unbound variable errors no longer occur when a Google Analytics result is zero

## [3.7.1] - 07-13-2018
### Added
- Added `deploy --build [project name]` for quickly building project assets
- Option to set `TERSE="TRUE"` in `deploy.conf` for slightly cleaner log files 
### Changed
- If a project is using `mina` and configured to build assets on every deployment, `deploy` will skip the redunant build step
- Test emails now contain more project information
- Improved readability of log files
- Improved unit testing
- Cleaned up language for more consistency
### Fixed
- Trapped an error that prevented `deploy --monitor-test [project]` from working

## [3.7] - 05-03-2018
### Added
- Digests now include information about recent malware scans, uptime, latency, and backup stats 
- Invoice creation is now available via [InvoiceNinja](https://www.invoiceninja.org/)'s API using `deploy --invoice`
- Added a very simple built-in web deployment method for instances when using something like `mina` is unavailble
- Added malware scanning using [Nikto](https://www.cirt.net/Nikto2)
### Changed
- Ports other than 22 can be used for SSH/SCP functions
- Running with the `--automate` switch now requires the branch defined as "master" must be currently checked out. The behavior is the equivalent of setting `CHECK_BRANCH="${MASTER}"`

## [3.6.7] - 03-05-2018
### Added
- Configuration files now upgrade in place if needed when new versions of `deploy` are released
- Statistic reports now display server uptime, latency, and a few handy Google analytics stats
### Changed
- Configuration files restructured for better readability 
- Many function and variable names changed for better consistency
### Fixed
- Remote hosted log files are now correctly deleted when they expire
- Fixed a crash that could occur when creating statistics for projects with code in approval queue
- Reports for the month of January now generate correctly
- Fixed a bug that could rarely report an incorrect Wordpress version number
- Google analytics no longer incorrectly display for projects that do not use them
- User configuration files are now created more reliably

## [3.6.6] - 01-13-2018
### Added
- Server health information now included in email/html logs via integration with [PHP Server Monitor](http://www.phpservermonitor.org/) using this [API](https://github.com/skydiver/PHP-Server-Monitor-API)
- Option to include web hosting as a line item on monthly reports
- Remote servers can now host project logs, digests, statistics, and reports
- New release check now runs upon launch
### Changed
- Item descriptions are now editable in reports 
- Cleaned up email output generated using `deploy --email-test`
- Report URLs are now formatted `report/YEAR-MONTH.php` instead of using a hard to remember string
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
- Running as root is no longer allowed; this can be overridden by setting `ALLOW_ROOT="TRUE"`
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
- Fixed issue with deploy_project() not executing deployment command correctly

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

[Unreleased]: https://github.com/EMRL/deploy/compare/v3.8.5...HEAD
[3.8.5]: https://github.com/EMRL/deploy/compare/v3.8.4...v3.8.5
[3.8.4]: https://github.com/EMRL/deploy/compare/v3.8.3...v3.8.4
[3.8.3]: https://github.com/EMRL/deploy/compare/v3.8.2...v3.8.3
[3.8.2]: https://github.com/EMRL/deploy/compare/v3.8...v3.8.2
[3.8]: https://github.com/EMRL/deploy/compare/v3.7.4...v3.8
[3.7.4]: https://github.com/EMRL/deploy/compare/v3.7.3...v3.7.4
[3.7.3]: https://github.com/EMRL/deploy/compare/v3.7.2...v3.7.3
[3.7.2]: https://github.com/EMRL/deploy/compare/v3.7.1...v3.7.2
[3.7.1]: https://github.com/EMRL/deploy/compare/v3.7...v3.7.1
[3.7]: https://github.com/EMRL/deploy/compare/v3.6.7...v3.7
[3.6.7]: https://github.com/EMRL/deploy/compare/v3.6.6...v3.6.7
[3.6.6]: https://github.com/EMRL/deploy/compare/v3.6.5...v3.6.6
[3.6.5]: https://github.com/EMRL/deploy/compare/v3.6.4...v3.6.5
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

