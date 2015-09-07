#!/bin/bash
#
# doinst.sh
#
# Installs deployment files for use system-wide
if [ ! -d /etc/deploy ]; then
  sudo mkdir /etc/deploy
fi
sudo cp etc/* /etc/deploy

if [ ! -d /etc/deploy/lib ]; then
  sudo mkdir /etc/deploy/lib
fi
sudo cp  lib/* /etc/deploy/lib
sudo cp deploy.sh /usr/local/bin/deploy
sudo chmod 755 /usr/local/bin/deploy
exit