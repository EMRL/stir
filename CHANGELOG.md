# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]
- Option to include error messages in Slack integration
- Option added to projects' ```config/deploy.sh``` to enforce repo to have a certain branch checked out before beginning deployment session. 

## [3.3] - 02-03-2015
- Added ssh key detection, allows manual login to repo host if keys not found
- Added Slack integration
- Added ```deploy --force --update --quiet``` for unattended Wordpress plugin/core updates via cron scheduling 
- Added ```deploy --current``` which will allow for deployment of current working directory if a project is found
- Added ```deploy --skip-update```

## 3.2 - N/A
- Skipped version, internal release only

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






[Unreleased]: https://github.com/EMRL/deploy/compare/v3.3...HEAD
[3.3]: https://github.com/EMRL/deploy/compare/v3.1...v3.3
[3.1]: https://github.com/EMRL/deploy/compare/v3.0...v3.1
[3.0]: https://github.com/EMRL/deploy/commits/v3.0

