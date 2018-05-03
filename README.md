# Deploy

[![release](https://img.shields.io/badge/release-v3.7-blue.svg?style=flat)](https://github.com/EMRL/deploy/releases/latest)
[![Build Status](https://travis-ci.org/EMRL/deploy.svg?branch=master)](https://travis-ci.org/EMRL/deploy)

`deploy` is designed to speed up, automate, and integrate project deployment. Its main focus is Wordpress websites, but it can be used with any code repository. 

[Changelog](https://github.com/EMRL/deploy/blob/master/CHANGELOG.md)

This script is in daily use at [EMRL](http://emrl.com), an advertising, design, and development agency in northern California. If you have any questions, please feel free to contact us.

Please note that our documentation here is nearly useless, and there is quite a bit of setup involved in getting this running reliably. A full setup guide is coming soon™.

## Startup Options

```
Usage: deploy [options] [target] ...

Options:
  -F, --force            Skip all user interaction, forces 'Yes' to all actions
  -S, --skip-update      Skip any Wordpress core/plugin updates
  -u, --update           If no available Wordpress updates, halt deployment
  -U, --update-only      Deploy only Wordpresss plugin/core updates
  -P, --publish          Publish current production code to live environment
  -m, --merge            Force merge of branches
  -c, --current          Deploy a project from current working directory          
  -t, --time             Add time to project management integration
  -V, --verbose          Output more process information to screen
  -q, --quiet            Display minimal output on screen
  -h, --help             Display this help and exit
  -v, --version          Output version information and exit

Other Options:
  --automate             For unattended deployment via cron
  --approve              Approve and deploy queued code changes
  --deny                 Deny queued code changes
  --digest               Create and send weekly digest
  --report               Create a monthly activity report
  --no-check             Override active file and server checks
  --stats                Generate project statistics pages
  --invoice              Create an invoice
  --strict               Any error will halt deployment completely
  --debug                Run in debug mode
  --unlock               Delete expired lock files
  --repair               Repair a deployment after merge failure
  --scan                 Scan production hosts for malware issues
  --ssh-test             Validate SSH key setup
  --email-test           Test email configuration
  --slack-test           Test Slack integration
  --post-test            Test webhook integration  
  --analytics-test       Test Google Analytics authentication
  --monitor-test         Test production server uptime and latency monitoring
  --function-list        Output a list of all functions()
  --variable-list        Output a project's declared variables 
```

[![asciicast](https://asciinema.org/a/mMCid9O2BK7JrpocQuSl3CRkP.png)](https://asciinema.org/a/mMCid9O2BK7JrpocQuSl3CRkP?t=0)

## How It Works

Basically, this thing consolidates a boatload of commands into a single command that simplifies web app deployment from a development or staging environment to a production server. 

`deploy` requires [`git`](https://git-scm.com/), and will make use of [`wp-cli`](http://wp-cli.org/), [`grunt`](http://gruntjs.com/), [`npm`](https://www.npmjs.com/), and  [`mina`](http://nadarei.co/mina/) if they are installed.

## Installation

`deploy` can be run from wherever you've installed it, but if you'd like it to be installed server-wide, follow the instructions below. 

1. In the `deploy` directory, type `sudo ./install/doinst.sh` and enter your sudo password when/if asked
2. That's it. By default `deploy` is installed to `/usr/local/bin/` and support files are installed to `/etc/deploy/`

## Configuration

Configuration is handled globally in the `etc/deploy.conf` file. Individual users also have their own settings in `~/.deployrc`

Repositories can each have their own deploy configuration. An example of this file can be [found here](https://github.com/EMRL/deploy/blob/master/etc/deploy.sh).

## Slack

For workgroups and teams that use it, `deploy` is able to integrate with Slack. You'll need to set up an "Incoming Webhook" custom integration on the Slack side to get this ready to roll. See https://YOURTEAMNAME.slack.com/apps/manage/custom-integrations to get going. Once you think you've got Slack configured, run `deploy --slack-test [project]` to test.

## Autopilot

`deploy --automate` works well for unattended updates of Wordpress sites; great for maintaining updates via a crontab. An example cron script can be [found here](https://github.com/EMRL/deploy/blob/master/etc/cron/deploy.cron.example). Running in this mode, the project will only be deployed if there are Wordpress core or plugin updates. If other code changes are detected the project will not be auto-updated. Smart Commits must be enabled or nothing will be deployed.

## Contact

* <http://emrl.com/>
* <https://www.facebook.com/advertisingisnotacrime>
