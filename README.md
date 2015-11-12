Deploy
=============
This is a multi-use deployment script, with a focus on publishing Wordpress sites and web apps to live environments. This script is in daily use at [EMRL](http://emrl.com), an advertising agency in northern California. If you have any questions, please feel free to contact us.

```
Usage: deploy [options] [target] ...
Options:
  -u, --upgrade     If there are no available upgrades, halt deployment
  -F, --force       Skip all user interaction, forces 'Yes' to all actions.
  -s, --strict      Any error will halt deployment completely
  -V, --verbose     Output more process information to screen
  -d, --debug       Run in debug mode
  -h, --help        Display this help and exit
  -v, --version     Output version information and exit
```

How It Works
--------
Maybe I'll finish this at some point. Basically this thing is a wrapper that simplifies web app deployment from a development environment to a production server. At the moment is mostly focused on Wordpress projects but in theory it should work for other stuff too.

This script requires [`git`](https://git-scm.com/), and will make use of [`wp-cli`](http://wp-cli.org/), [`grunt`](http://gruntjs.com/), [`npm`](https://www.npmjs.com/), and  [`mina`](http://nadarei.co/mina/) if they are installed.

Installation
--------
`deploy` can be run from wherever you've installed it, but if you'd like it to be installed server-wide, follow the instructions below. 

1. In the `deploy` directory, type `sudo ./install/doinst.sh` and enter your sudo password when/if asked
2. That's it. By default `deploy` is installed to `/usr/local/bin/` and support files are installed to `/etc/deploy/`

Configuration
--------
Configuration is handled in the `etc/deploy.conf` file. Individual users can also keep their own settings in `~/.deployrc`

Repositories can each have their own deploy configuration. An example of this file can be [found here](https://github.com/EMRL/deploy/blob/master/etc/deploy.sh).

Running on Autopilot
--------
As of 3.1, `deploy -Fu` or `deploy --force --upgrade` should work well for unattended updates of Wordpress site plugin and core updates; great for maintaining updates via a crontab. Running in this mode, the project will only be deployed if there are Wordpress core or plugin updates. If other code changes are detected the project will not be auto-updated. Smart Commits must be enabled or nothing will be deployed.

Contact
--------
* <http://emrl.com/>
* <https://www.facebook.com/advertisingisnotacrime>