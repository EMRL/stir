#!/bin/bash
#
# git()
#
# Handles git related processes
trace "Loading git functions"

function gitcheck() {
	if [ ! -d $WORKPATH/$SITE ]; then
  		error $WORKPATH/$SITE "is not a valid directory."
   		exit
	fi

	if [ -f $WORKPATH/$SITE/.git/index ]; then
	    sleep 1
	else
   		error "There is nothing at " $WORKPATH/$SITE "to deploy."
   		exit
	fi
	}

function gitcm() {
	echo -e "${green}Checking out master branch...${endColor}"
	git checkout master 2>/dev/null 1>>/tmp/${PWD##*/}.log &
        while ps |grep $! &>/dev/null; do
        echo -n "."
        sleep 2
        done
        echo ""
	}