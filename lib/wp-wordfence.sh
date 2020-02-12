#!/usr/bin/env bash
#
# wp-wordfence.sh
#
###############################################################################
# Works around issues potentially caused when Wordfence is running on the 
# staging server
###############################################################################

function wf_check() {
  if [[ "${WFCHECK}" == "TRUE" ]]; then
    if [[ -f "${WORKPATH}/${APP}${WPROOT}${WPAPP}/wflogs/config.php" ]]; then
      trace "Wordfence detected"; empty_line
      warning "Wordfence firewall detected, and may cause issues with deployment."
      if [[ "${FORCE}" = "1" ]] || [[ "${QUIET}" = "1" ]]; then
        error "Deployment can not continue while Wordfence firewall is enabled."
      else
        if yesno --default yes "Attempt to repair files? (sudo required) [Y/n] "; then
          "${WPCLI}"/wp plugin deactivate --no-color wordfence &>> "${logFile}"; WFOFF="1"
          sudo rm -rf "${WORKPATH}/${APP}${WPROOT}${WPAPP}/wflogs" &>> $logFile
          # Remove from repo history, in case .gitignore doesn't have them excluded
          if ! grep -aq "wflog" "${WORKPATH}/${APP}/.gitignore"; then
            cd "${WORKPATH}"/"${APP}"; \
            git filter-branch --index-filter "git rm -rf --cached --ignore-unmatch ${WPROOT}${WPAPP}/wflogs > /dev/null" HEAD &>> "${logFile}" &
            spinner $!
            rm -rf .git/refs/original/ && git reflog expire --all &&  git gc --aggressive --prune &>> "${logFile}" &
            spinner $!
            cd "${WORKPATH}"/"${APP}${WPROOT}"; \
          fi
          sleep 1
        else
          error "Deployment can not continue while Wordfence firewall is enabled."
        fi
      fi
    fi
  fi
}
