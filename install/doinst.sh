#!/bin/bash
#
# doinst.sh
#
# Installs deployment files for use system-wide

# Check for root
if [[ $EUID -ne 0 ]]; then
  echo "You must have root access to install - try 'sudo install/doinst.sh'" 2>&1
  exit 1
else

if [ ! -d /etc/deploy ]; then
  mkdir /etc/deploy
fi
cp etc/* /etc/deploy

if [ ! -d /etc/deploy/lib ]; then
  mkdir /etc/deploy/lib
fi
cp  lib/* /etc/deploy/lib
cp deploy.sh /usr/local/bin/deploy
chmod 755 /usr/local/bin/deploy
exit

fi


