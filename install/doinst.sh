#!/usr/bin/bash
#
# doinst.sh
#
# Installs deployment files for use system-wide

# Error check function
function errorChk() {
	EXITCODE=$?; 
	if [[ "${EXITCODE}" != "0" ]]; then 
		echo "Error ${EXITCODE}: deploy not installed."
		exit "${EXITCODE}"
	fi
}

# Check for root
if [[ "${EUID}" -ne 0 ]]; then
  echo "You must have root access to install - try 'sudo install/doinst.sh'" 2>&1
  exit 1
else
		if [[ ! -d /etc/deploy ]] && [[ ! -d /etc/deploy/lib ]] && [[ ! -d /etc/deploy/crontab ]]; then
		echo "Creating directories"
			if [[ ! -d /etc/deploy ]]; then
				sudo mkdir /etc/deploy; errorChk
			fi

			if [[ ! -d /etc/deploy/lib ]]; then
				sudo mkdir /etc/deploy/lib; errorChk
			fi

			if [[ ! -d /etc/deploy/lib/crontab ]]; then
				sudo mkdir /etc/deploy/lib/crontab; errorChk
			fi
		fi

	echo "Installing configuration files"
	sudo cp -R etc/* /etc/deploy; errorChk
	sudo cp etc/.deployrc /etc/deploy; errorChk

	if [[ ! -f /etc/deploy/deploy.conf ]]; then
		cp /etc/deploy/deploy-example.conf /etc/deploy/deploy.conf; errorChk
	fi

	cp -R lib/* /etc/deploy/lib; errorChk
	cp deploy.sh /usr/local/bin/deploy; errorChk
	sudo chmod 755 /usr/local/bin/deploy; errorChk
	echo "Successfully installed, try typing 'deploy' for help."
fi