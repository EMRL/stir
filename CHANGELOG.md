# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]
- Added ```deploy ---automate``` for scheduled update deployments. Equivalent to ```deploy --force --update --quiet``` with the addition of a flag to enable sending a scheduled update email notice to clients
- Recently changed file checks are now more accurate
- Added ability to save HTML logs to local filesystem
- Added ability to post log files to a remote host with scp
- Added option to delete log files after a certain amount of days
- Added HTML email log option, with custom templates assignable either globally or by project
- Added link to detailed log files from Slack messages 
- Logs are now only emailed and posted when something noteworthy has occured - e.g. a commit has been made or an error has occurred
- Changed checkout behavior - master branch is now only checked out when needed
- Cleaned up log output
- Changed default merge behavior - deploy will no longer perform automatic merges unless ran as ```deploy --merge``` or ```AUTOMERGE="TRUE"``` is defined in ```config/deploy.sh``` 
- Fixed a small bug when repo name is undeclared when not running ```deploy --current```
- Added more robust branch checking
- Added option to enforce server check

## [3.4] - 07-07-2016
- Added a more reliable method of updating Advanced Custom Fields Pro
- Added "Garbage Collection" mode to help keep your repo neat and tidy
- Fixed some issues that can cause permission problems in certain environments
- Added optional fix for Wordfence firewall permission problems
- Added check for .git/index permission issues

## [3.3.4] - 05-16-2016
- Fixed issue with pkgDeploy() not executing deployment command correctly
- Exit codes pass more reliably to Slack messages 
- Added [Travis CI](https://travis-ci.org/EMRL/deploy) tests
- Cleaned up many functions
- Cleaned up configuration files
- Added ```deploy --function-list``` to list all available functions() for help debugging with in the future

## [3.3.3] - 02-11-2016
- Added active file check as another failsafe when running as cron (```deploy --force --update --quiet```) to stop potential issues that may come up in multi-developer environments
- Added change log
- Running ```deploy --current``` will now deploy the current directory and no longer needs to be launched as ```deploy --current [project name]```
- Option to include error messages in Slack integration
- Option added to projects' ```config/deploy.sh``` to enforce repo to have a certain branch checked out before beginning deployment session. 
- Added ```deploy --slack-test``` to allow testing of Slack integration

## [3.3] - 02-03-2016
- Added ssh key detection, allows manual login to repo host if keys not found
- Added Slack integration
- Added ```deploy --force --update --quiet``` for unattended Wordpress plugin/core updates via cron scheduling 
- Added ```deploy --current``` which will allow for deployment of current working directory if a project is found
- Added ```deploy --skip-update```

## [3.1] - 11-12-2015
- Added install script
- Added progress indicators
- Extended verbose output
- Implemented logging
- Added "Smart Commits" - commit messages are generated automatically based on Wordpress core/plugin updates that have occured
- Configuration files for both the user, and the project are now automatically created if not found 

## [3.0] - 10-21-2015
- Old monolithic script rewritten
- Basic ```wp-cli``` integration  





[Unreleased]: https://github.com/EMRL/deploy/compare/v3.4...HEAD
[3.4]: https://github.com/EMRL/deploy/compare/v3.3.4...v3.4
[3.3.4]: https://github.com/EMRL/deploy/compare/v3.3.3...v3.3.4
[3.3.3]: https://github.com/EMRL/deploy/compare/v3.3...v3.3.3
[3.3]: https://github.com/EMRL/deploy/compare/v3.1...v3.3
[3.1]: https://github.com/EMRL/deploy/compare/v3.0...v3.1
[3.0]: https://github.com/EMRL/deploy/commits/v3.0
