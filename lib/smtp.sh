#!/usr/bin/env bash
#
# smtp.sh
#
###############################################################################
# Send emails directly via SMTP using ssmtp
###############################################################################

function smtp_check() {
  if [[ "${USE_SMTP}" == "TRUE" ]] && [[ -n "${ssmtp_cmd}" ]]; then
    sendmail_cmd="${ssmtp_cmd}"
  fi
}
