#!/bin/bash
#
# loader.sh
#
# A sub-wrapper for loading external functions.

source "${deployPath}/lib/func.sh"			# Always load this one first
source "${deployPath}/lib/alerts.sh"
source "${deployPath}/lib/colors.sh"
source "${deployPath}/lib/git.sh"
source "${deployPath}/lib/lock.sh"
source "${deployPath}/lib/npm.sh"
source "${deployPath}/lib/pmfix.sh"
source "${deployPath}/lib/wp.sh"
source "${deployPath}/lib/yesno.sh"