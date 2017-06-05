#!/bin/bash
#
# sshChk()
#
# 
#trace "Loading SSH checks"

function sshChk() {
	if [[ "${NOKEY}" != "TRUE" ]]; then
		trace "Checking SSH configuration"
		if [[ "${REPOHOST}" == *"bitbucket"* ]]; then
			ssh -oStrictHostKeyChecking=no git@bitbucket.org &> /dev/null 2>&1
			if [[ $? != "0" ]]; then
				error "git@bitbucket.org: SSH check failed"
			else
				[[ "${SSHTEST}" == "1" ]] && console "git@bitbucket.org: OK"
				trace "git@bitbucket.org: OK"
			fi
		elif [[ "${REPOHOST}" == *"github"* ]]; then
			ssh -oStrictHostKeyChecking=no git@github.org &> /dev/null
			if [[ $? != "0" ]]; then
				error "git@github.org: SSH check failed"
			else
				[[ "${SSHTEST}" == "1" ]] && console "git@bitbucket.org: OK"
				trace "git@github.org: OK"
			fi
		fi
	fi
}
