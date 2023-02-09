#!/usr/bin/env bash
#
# smtp.sh
#
###############################################################################
# Send emails directly via SMTP using ssmtp
###############################################################################

function check_smtp() {
  if [[ "${USE_SMTP}" == "TRUE" ]] && [[ -n "${ssmtp_cmd}" ]]; then
    sendmail_cmd="${ssmtp_cmd}"
  fi
}
