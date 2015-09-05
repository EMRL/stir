#!/bin/bash
#
# loader.sh
#
# A sub-wrapper for loading external functions.

source "${deployPath}/lib/func.sh"			# Always load this one first
source "${deployPath}/lib/alerts.sh"
source "${deployPath}/lib/git.sh"
source "${deployPath}/lib/lock.sh"
source "${deployPath}/lib/pm.sh"
source "${deployPath}/lib/permfix.sh"
source "${deployPath}/lib/wp.sh"
source "${deployPath}/lib/yesno.sh"