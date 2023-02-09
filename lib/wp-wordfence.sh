#!/usr/bin/env bash
#
# wp-wordfence.sh
#
###############################################################################
# Works around issues potentially caused when Wordfence is running on the 
# staging server
###############################################################################

function wf_check() {
  if [[ "${WF_CHECK}" == "TRUE" ]]; then
    if [[ -f "${WORK_PATH}/${APP}${WP_ROOT}${WP_APP}/wflogs/config.php" ]]; then
      trace "Wordfence detected"; empty_line
      warning "Wordfence firewall detected, and may cause issues with deployment."
      if [[ "${FORCE}" = "1" ]] || [[ "${QUIET}" = "1" ]]; then
        error "Deployment can not continue while Wordfence firewall is enabled."
      else
        if yesno --default yes "Attempt to repair files? (sudo required) [Y/n] "; then
          eval "${wp_cmd}" plugin deactivate --no-color wordfence &>> "${log_file}"; WFOFF="1"
          sudo rm -rf "${WORK_PATH}/${APP}${WP_ROOT}${WP_APP}/wflogs" &>> $log_file
          # Remove from repo history, in case .gitignore doesn't have them excluded
          if ! grep -aq "wflog" "${WORK_PATH}/${APP}/.gitignore"; then
            cd "${WORK_PATH}"/"${APP}"; \
            git filter-branch --index-filter "git rm -rf --cached --ignore-unmatch ${WP_ROOT}${WP_APP}/wflogs > /dev/null" HEAD &>> "${log_file}" &
            spinner $!
            rm -rf .git/refs/original/ && git reflog expire --all &&  git gc --aggressive --prune &>> "${log_file}" &
            spinner $!
            cd "${WORK_PATH}"/"${APP}${WP_ROOT}"; \
          fi
          sleep 1
        else
          error "Deployment can not continue while Wordfence firewall is enabled."
        fi
      fi
    fi
  fi
}
