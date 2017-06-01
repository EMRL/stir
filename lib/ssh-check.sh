#!/bin/bash
#
# sshChk()
#
# 
#trace "Loading SSH checks"

function sshChk() {
	notice "Checking SSH Keys..."
	ssh -oStrictHostKeyChecking=no git@bitbucket.org
	ssh -oStrictHostKeyChecking=no git@github.org
}
