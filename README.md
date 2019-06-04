![Stir](https://raw.githubusercontent.com/EMRL/stir/master/img/logo.png)

[![release](https://img.shields.io/badge/release-v4.0.pre-blue.svg?style=flat)](https://github.com/EMRL/stir/releases/latest)
[![Build Status](https://travis-ci.org/EMRL/stir.svg?branch=master)](https://travis-ci.org/EMRL/stir)

`stir` is designed to speed up, automate, and integrate project commits, management, and deployment. Its main focus is Wordpress websites, but it can be used with any code repository. 

[Changelog](https://github.com/EMRL/stir/blob/master/CHANGELOG.md)

`stir` is in daily use at [EMRL](http://emrl.com), an advertising, design, and development agency in northern California. If you have any questions, please feel free to contact us.

Please note that our documentation here is nearly useless, and there is quite a bit of setup involved in getting this running reliably. A full setup guide is coming soon™.

## Startup Options

```
Usage: stir [options] [target] ...
Options:
  -F, --force            Skip all user interaction, forces 'Yes' to all actions
  -S, --skip-update      Skip any Wordpress core/plugin updates
  -u, --update           If no available Wordpress updates, halt deployment
  -U, --update-only      Deploy only Wordpresss plugin/core updates
  -D, --deploy           Deploy current production code to live environment
  -m, --merge            Force merge of branches
  -c, --current          Deploy a project from current directory          
  -t, --time             Add time to project management integration
  -p, --prepare          Clone and setup local Wordpress project
  -V, --verbose          Output more process information to screen
  -q, --quiet            Display minimal output on screen
  -v, --version          Output version information and exit
  -h, --help             Display this help and exit
  -H, --more-help        Display extended help and exit

Other Options:
  --automate             For unattended execution via cron
  --approve              Approve and deploy queued code changes
  --deny                 Deny queued code changes
  --build                Build project assets
  --prepare              Prepare project
  --reset                Resets local project files
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
  --test-ssh             Validate SSH key setup
  --test-email           Test email configuration
  --test-slack           Test Slack integration
  --test-webhook         Test webhook integration  
  --test-analytics       Test Google Analytics authentication
  --test-monitor         Test production server uptime and latency monitoring
  --function-list        Output a list of all functions()
  --variable-list        Output a project's declared variables
```

## How It Works

`stir` consolidates a boatload of functions into a single command that simplifies web app deployment from a development or staging environment to a production server. It also can provide clients with a dashboard of information about their project.

![Dashboard](https://raw.githubusercontent.com/EMRL/stir/master/img/dashboard.png)

`stir` requires [`git`](https://git-scm.com/), and will make use of [`wp-cli`](http://wp-cli.org/), [`grunt`](http://gruntjs.com/), [`npm`](https://www.npmjs.com/), [`composer`](https://getcomposer.org/), and  [`mina`](http://nadarei.co/mina/) if they are installed.

## Installation

`stir` can be run from anywhere, but if you'd like it to be installed server-wide follow the instructions below. 

1. In the `stir` directory, type `sudo ./install/doinst.sh` and enter your sudo password when/if asked
2. That's it. By default `stir` is installed to `/usr/local/bin/` and support files are installed to `/etc/stir/`

## Configuration

Configuration is handled globally in the `etc/stir/global.conf` file. Individual users also have their own settings in `~/.stirrc`

Repositories can each have their own configuration. An example of this file can be [found here](https://github.com/EMRL/stir/blob/master/etc/stir.sh).

## Slack

For workgroups and teams that use it, `stir` is able to integrate with Slack. You'll need to set up an "Incoming Webhook" custom integration on the Slack side to get this ready to roll. See https://YOURTEAMNAME.slack.com/apps/manage/custom-integrations to get going. Once you think you've got Slack configured, run `stir --slack-test [project]` to test.

## Autopilot

`stir --automate` works well for unattended updates of Wordpress sites; great for maintaining updates via a crontab. An example cron script can be [found here](https://github.com/EMRL/stir/blob/master/etc/cron/stir.cron.example). Running in this mode, the project will only be deployed if there are Wordpress core or plugin updates. If other code changes are detected the project will not be auto-updated. Smart Commits must be enabled or nothing will be deployed.

## Contact

* <http://emrl.com/>
* <https://www.facebook.com/advertisingisnotacrime>
