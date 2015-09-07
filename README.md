
Deploy
=============
A web app deployment script, with a focus on publishing Wordpress sites to live environments. This script is in daily use at [EMRL](http://emrl.com). an advertising agency in northern California. If you have any questions, please feel free to contact us.

```
Usage: deploy [options] [target] ...
Options:
- -F, --force       Skip all user interaction, forces 'Yes' to all actions.
- -Q, --forcequiet  Like the --force command, with minimal output to screen
- -s, --strict      Run in Strict mode. Any error will halt deployment completely
- -V, --verbose     Output more process information to screen
- -d, --debug       Run in debug mode
- -h, --help        Display this help and exit
- -v, --version     Output version information and exit
```

How It Works
--------
Maybe I'll finish this at some point. Basically this thing is a wrapper that simplifies web app deployment from a development environment to a production server. At the moment is mostly focused on Wordpress projects but in theory it should work for other stuff too.

-deploy- requires [`git`](https://git-scm.com/), and will make use of [`wp-cli`](http://wp-cli.org/), [`grunt`](http://gruntjs.com/), [`npm`](https://www.npmjs.com/), and  [`mina`](http://nadarei.co/mina/) if they are installed.

Configuration
--------
Configuration is handled in the `etc/deploy.conf` file. Individual users can also keep their own settings in `~/.deployrc`

```
# Application settings
#
# This is the root directory for all of your development projects, with no trailing slash.
WORKPATH="/var/www/html" 

# The command your system uses for deployment			
DEPLOY="mina deploy"

# Permission values
#
# You may run into weird permission issues if working in a multiuser environment, we do.
#
# Lead developer username and group
DEVUSER="cworrell" # Lead developer username
DEVGRP="web" # Lead developer group
#
# The user/group that runs the apache server
APACHEUSER="apache" # Apache user
APACHEGRP="apache" # Apache group

# Email settings
#
# Who should receive log's via email
TO="fdiebel@emrl.com"
#
# Other settings
SUBJECT="[EMRL] Deployment" #Email log subject line
#
# Email log when deployment crashes/fails
EMAILERROR="1" 
#
# Email log when deployment is successful
EMAILSUCCESS="1" 
#
# Email log when a user quits dfeployment early
EMAILQUIT="1" 

# Override flags - uncomment and set to "1" to use. 
# Setting these values will disallow input of that user flag
#
# VERBOSE="1" 
# DEBUG="1" 
# STRICT="1" 
# FORCE="1"						
# FORCEQUIET="1"
```

Installation
--------
`deploy` can be run from wherever you've installed it, but if you'd like it to be installed server-wide, follow the instructions below. 

1. In the `deploy` directory, type `sh ./install/doinst.sh` and enter your sudo password when/if asked
2. That's it. By default `deploy` is installed to `/usr/local/bin/` and support files are installed to `/etc/deploy/`

Contact
--------
* <http://emrl.com/>
* <https://www.facebook.com/advertisingisnotacrime> 

