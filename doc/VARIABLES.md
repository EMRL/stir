# Variable List
This is a list of all the variables used. It is not yet complete, and most non-environment variables will be renamed to follow the conventions [`outlined here`](https://google.github.io/styleguide/shell.xml)

## Startup Variables
```
UPGRADE
SKIPUPDATE
CURRENT
MERGE
VERBOSE
QUIET
STRICT
DEBUG
FORCE
SLACKTEST
```

## Constants and Environment Variables
```
CLEARSCREEN
WORKPATH
CONFIGDIR
REPOHOST
WPCLI
SMARTCOMMIT
GITSTATS
EMAILHTML
NOPHP
FIXPERMISSIONS
DEVUSER
DEVGROUP
APACHEUSER
APACHEGROUP
TO
SUBJECT
EMAILERROR
EMAILSUCCESS       
EMAILQUIT
FROMDOMAIN
FROMUSER
POSTEMAILHEAD
POSTEMAILTAIL
POSTTOSLACK
SLACKURL
POSTURL
NOKEY
PROJNAME
PROJCLIENT
DEVURL
PRODURL
REPO
MASTER
PRODUCTION
COMMITMSG
DEPLOY
DONOTDEPLOY
TASK
CHECKBRANCH
ACTIVECHECK
CHECKTIME
WFCHECK
ACFKEY
WFOFF
AUTOMERGE
```

## Variables (Format needs to change)
```
VERSION
NOW
DEV
deploy_cmd
optstring
options
APP
logFile
wpFile
coreFile
postFile
trshFile
statFile
urlFile
htmlFile
deployPath
etcLocation
libLocation
POSTEMAIL
current_branch
error_msg
active_files
```

## Logfiles
There are way way way too many logfiles in use at this time. I'm going to be tidying this up.
````
Main Log file: /tmp/[repo].log-####.log
Plugin update log: /tmp/[repo].wp-#####.log
Core update log: /tmp/[repo].core-####.log
Post log: /tmp/[repo].wtf-####.log
Trash output: /tmp/[repo].trsh-####.log
Stats output: /tmp/[repo].stat-####.log
URL output: /tmp/[repo].url-####.log
HTML log output: /tmp/[repo].html-####.log
````