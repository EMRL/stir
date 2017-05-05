# Deploy

[![Build Status](https://travis-ci.org/EMRL/deploy.svg?branch=master)](https://travis-ci.org/EMRL/deploy)

This is a multi-use deployment script, with a focus on publishing web apps to live environments. This script is in daily use at [EMRL](http://emrl.com), an advertising, design, and development agency in northern California. If you have any questions, please feel free to contact us.

[View Changelog](https://github.com/EMRL/deploy/blob/master/CHANGELOG.md)

## Startup Options

```
Usage: deploy [options] [target] ...

Options:
  -F, --force            Skip all user interaction, forces 'Yes' to all actions
  -S, --skip-update      Skip any Wordpress core/plugin updates
  -u, --update           If no available Wordpress updates, halt deployment
  -P, --publish          Publish current production code to live environment
  -m, --merge            Force merge of branches
  -c, --current          Deploy a project from current working directory          
  -V, --verbose          Output more process information to screen
  -q, --quiet            Display minimal output on screen
  -h, --help             Display this help and exit
  -v, --version          Output version information and exit

Other Options:
  --approve              Approve proposed changes and queue for deployment
  --deny                 Deny proposed changes
  --automate             For unattended deployment, equivalent to -Fuq
  --digest               Create and send weekly digest
  --no-check             Override active file and server checks 
  --gitstats             Generate git statistics
  --strict               Any error will halt deployment completely
  --debug                Run in debug mode
  --unlock               Delete expired lock files
  --email-test           Test email configuration
  --slack-test           Test Slack integration
  --analytics-test       Test Google Analytics authentication
  --function-list        Output a list of all functions()
  --variable-list        Output a project's declared variables 
```

## How It Works

Basically, this thing is a wrapper that simplifies web app deployment from a development environment to a production server. At the moment is mostly focused on Wordpress projects but in theory it should work for other stuff too.

This script requires [`git`](https://git-scm.com/), and will make use of [`wp-cli`](http://wp-cli.org/), [`grunt`](http://gruntjs.com/), [`npm`](https://www.npmjs.com/), and  [`mina`](http://nadarei.co/mina/) if they are installed.

## Installation

`deploy` can be run from wherever you've installed it, but if you'd like it to be installed server-wide, follow the instructions below. 

1. In the `deploy` directory, type `sudo ./install/doinst.sh` and enter your sudo password when/if asked
2. That's it. By default `deploy` is installed to `/usr/local/bin/` and support files are installed to `/etc/deploy/`

## Configuration

Configuration is handled in the `etc/deploy.conf` file. Individual users can also keep their own settings in `~/.deployrc`

Repositories can each have their own deploy configuration. An example of this file can be [found here](https://github.com/EMRL/deploy/blob/master/etc/deploy.sh).

## Integration

For workgroups and teams that use it `deploy` is able to integrate with Slack. You'll need to set up an "Incoming Webhook" custom integration on the Slack side to get this ready to roll. See https://YOURTEAMNAME.slack.com/apps/manage/custom-integrations to get going. Once you think you've got Slack configured, run `deploy --slack-test` to test.

## Running on Autopilot

As of 3.5, the proper method of running automated deployments is `deploy --automate` as opposed to the previous method which was `deploy --force --upgrade --quiet`. The new method adds a flag to optionally deliver an email after the automated update. The old wmethod can still be used but will not trigger the email. 

`deploy --automate` works well for unattended updates of Wordpress sites; great for maintaining updates via a crontab. An example cron script can be [found here](https://github.com/EMRL/deploy/blob/master/etc/cron/deploy.cron.example). Running in this mode, the project will only be deployed if there are Wordpress core or plugin updates. If other code changes are detected the project will not be auto-updated. Smart Commits must be enabled or nothing will be deployed.

## Contact

* <http://emrl.com/>
* <https://www.facebook.com/advertisingisnotacrime>
