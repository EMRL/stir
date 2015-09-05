#!/bin/bash
#
# git()
#
# Handles git related processes
echo "DEBUG: Loading git()"

function gitcheck() {
	if [ ! -d "/var/www/html/"$SITE ]; then
  		echo "ERROR: /var/www/html/"$SITE" is not a valid directory."
   		exit
	fi

	if [ -f /var/www/html/$SITE/.git/index ]; then
	    sleep 1
	else
   		echo "There is nothing at /var/www/html/"$SITE" to deploy."
   		exit
	fi
}

