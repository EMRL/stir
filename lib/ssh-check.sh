#!/bin/bash
#
# sshChk()
#
# 
trace "Loading sshChk()"

function sshChk() {
	notice "Checking SSH Keys..."
	ssh -oStrictHostKeyChecking=no git@bitbucket.org
	ssh -oStrictHostKeyChecking=no git@github.org
}
