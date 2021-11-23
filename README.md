﻿![Stir](https://raw.githubusercontent.com/EMRL/stir/master/img/logo.png)

[![release](https://img.shields.io/github/v/release/emrl/stir?sort=semver)](https://github.com/EMRL/stir/releases/latest)
[![Github issues](https://img.shields.io/github/issues/emrl/stir)](https://github.com/EMRL/stir/issues)

`stir` is designed to speed up, automate, and integrate project commits, management, and deployment. Its main focus is Wordpress websites, but it can be used with any code repository. 

[Changelog](https://github.com/EMRL/stir/blob/master/CHANGELOG.md) &bull; [Known bugs](https://github.com/EMRL/stir/issues?q=is%3Aopen+is%3Aissue+label%3Abug) &bull; [Installation](https://github.com/EMRL/stir/wiki)

`stir` is in daily use at [EMRL](http://emrl.com), an advertising, design, and development agency in northern California. If you have any questions, please feel free to contact us.

Please note that there is quite a bit of setup involved in getting this running reliably. A full setup guide is coming soon™ but for now check out what we've got started in the [wiki documentation](https://github.com/EMRL/stir/wiki).

## Startup Options

```
Usage: stir [options] [target] ...
Options:
  -F, --force            Skip all user interaction, forces 'Yes' to all actions
  -S, --skip-update      Skip any Wordpress core/plugin updates
  -u, --update           If no available Wordpress updates, halt deployment
  -U, --update-only      Deploy only Wordpresss plugin/core updates
  -D, --deploy           Deploy current production code to live environment
  -m, --merge            Force merge of all branches
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
  --build                Build project assets
  --prepare              Prepare project
  --reset                Resets local project files
  --prepare-with-reset   Reset and prepare project
  --digest               Create and send weekly digest
  --report               Create a monthly activity report
  --no-check             Override active file and server checks
  --stats                Generate project statistics pages
  --invoice              Create an invoice
  --strict               Any error will halt deployment completely
  --debug                Run in debug mode
  --debug-to-file        Save debug output to a file
  --unlock               Delete expired lock files
  --repair               Repair a deployment after merge failure
  --scan                 Scan production hosts for malware issues
  --update-acf           Force an update or reinstall of ACF Pro
  --test-ssh             Validate SSH key setup
  --test-email           Test email configuration
  --test-slack           Test Slack integration
  --test-webhook         Test webhook integration  
  --test-analytics       Test Google Analytics authentication
  --test-monitor         Test production server uptime and latency monitoring
  --TEST_BUGSNAG         Test Bugsnag integration
  --show-settings        Display current global and project settings
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

Configuration is handled globally in the `/etc/stir/global.conf` file. Individual users also have their own settings in `~/.stirrc`

Repositories can each have their own configuration. An example of this file can be [found here](https://github.com/EMRL/stir/blob/master/etc/stir-global.conf).

## Integration

`stir` is able to integrate with many third-party platforms, including [Slack](https://slack.com), [Google Analytics](https://google.com/analytics/), [PHP Server Monitor](https://phpservermonitor.org), [Bugsnag](https://bugsnag.com), [Invoice Ninja](https://invoiceninja.com), and more. Check out the [integration wiki](https://github.com/EMRL/stir/wiki/Integration) for more information.

## Autopilot

`stir --automate` works well for unattended updates of Wordpress sites; great for maintaining updates via a cron. An example cron script can be [found here](https://github.com/EMRL/stir/blob/master/etc/cron/stir.cron.example). Running in this mode, the project will only be deployed if there are Wordpress core or plugin updates. If other code changes are detected the project will not be auto-updated. Smart Commits must be enabled or nothing will be deployed.

## Contact

* <http://emrl.com/>
* <https://www.facebook.com/advertisingisnotacrime>
