#!/bin/bash
#
# doinst.sh
#
# Installs deployment files for use system-wide

# Error check function
function errorChk() {
	EXITCODE=$?; 
	if [[ $EXITCODE == 1 ]]; then 
		echo "Exiting on error, deploy not installed."
	fi
}

# Check for root
if [[ $EUID -ne 0 ]]; then
  echo "You must have root access to install - try 'sudo install/doinst.sh'" 2>&1
  exit 1
else
	if [ ! -d /etc/deploy ]; then
		mkdir /etc/deploy; errorChk
	fi
	cp etc/* /etc/deploy; errorChk
	if [ ! -d /etc/deploy/lib ]; then
		mkdir /etc/deploy/lib; errorChk
	fi
	cp lib/* /etc/deploy/lib; errorChk
	cp deploy.sh /usr/local/bin/deploy; errorChk
	chmod 755 /usr/local/bin/deploy; errorChk
	echo "Successfully installed, try typing 'deploy' for help."
fi