#!/usr/bin/bash
#
# doinst.sh
#
# Installs deployment files for use system-wide

# Error check function
function errorChk() {
	EXITCODE=$?; 
	if [[ $EXITCODE == 1 ]]; then 
		echo "Exiting on error, deploy not installed."
		exit 1
	fi
}

# Check for root
if [[ $EUID -ne 0 ]]; then
  echo "You must have root access to install - try 'sudo install/doinst.sh'" 2>&1
  exit 1
else
	if [ ! -d /etc/deploy ]; then
		sudo mkdir /etc/deploy; errorChk
	fi
	sudo cp -R etc/* /etc/deploy; errorChk
	sudo cp etc/.deployrc /etc/deploy; errorChk

	if [ ! -d /etc/deploy/lib ]; then
		sudo mkdir /etc/deploy/lib; errorChk
	fi

	if [ ! -d /etc/deploy/lib/crontab ]; then
		sudo mkdir /etc/deploy/lib/crontab; errorChk
	fi

	cp -R lib/* /etc/deploy/lib; errorChk
	cp deploy.sh /usr/local/bin/deploy; errorChk
	sudo chmod 755 /usr/local/bin/deploy; errorChk
	echo "Successfully installed, try typing 'deploy' for help."
fi