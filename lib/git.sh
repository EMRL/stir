#!/bin/bash
#
# git()
#
# Handles git related processes
trace "Loading git functions"

function gitCheck() {
	if [ ! -d $WORKPATH/$APP ]; then
  		error $WORKPATH/$APP "is not a valid directory."
   		exit
	fi

	if [ -f $WORKPATH/$APP/.git/index ]; then
	    sleep 1
	else
   		error "There is nothing at " $WORKPATH/$APP "to deploy."
   		exit
	fi
	}

function gitChkm() {
	echo -e "${green}Checking out master branch...${endColor}"
	git checkout master 2>/dev/null 1>>/tmp/${PWD##*/}.log &
        while ps |grep $! &>/dev/null; do
        echo -n "."
        sleep 2
        done
        echo ""
	}