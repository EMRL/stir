
Deploy
=============
A web app deployment script, with a focus on publishing Wordpress sites to live environments.

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
Maybe i'll finish this at some point. Basically this thing is a wrapper that simplifies web app deployment from a development environment to a production server. At the moment is mostly focused on Wordpress projects but in theory it should work for other stuff too.

It is heavily reliant on our environment here but shouldn't be too hard to tweak if you need to. [`deploy`](https://bitbucket.org/) makes use of [`git`](https://git-scm.com/), [`wp-cli`](http://wp-cli.org/), [`grunt`](http://gruntjs.com/), [`node.js`](https://nodejs.org/),  [`mina`](http://nadarei.co/mina/) and [Bit Bucket](https://bitbucket.org/)

Configuration
--------
Configuration is handled in the `etc/deploy.conf` file. Individual users can also keep their own settings in `~/.deployrc`

```
# Application settings
WORKPATH="/var/www/html" # No trailing slash
DEPLOY="mina deploy" # The command your system uses for deployment			

# Permission values
DEVUSER="cworrell" # Lead developer username
DEVGRP="web" # Lead developer group
APACHEUSER="apache" # Apache user
APACHEGRP="apache" # Apache group

# Email values
FROM="deploy@emrl.com" # Email log from address
TO="fdiebel@emrl.com" # Where to send logs
SUBJECT="[EMRL] Deployment" #Email log subject line

# When to send email, 1=yes, 0=no
EMAILERROR="1" # Email log when deployment crashes/fails
EMAILSUCCESS="1" # Email log when deployment is successful
EMAILQUIT="1" # Email log when a user quits dfeployment early

# Override flags - uncomment and set to "1" to use. 
# Setting these values will disallow input of that user flag
#VERBOSE="1" # Output more detailed process information to screen
#DEBUG="1" # Run in debug mode
#STRICT="1" # Run in Strict mode. Any error will
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

