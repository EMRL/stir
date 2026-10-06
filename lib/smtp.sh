#!/usr/bin/env bash
#
# smtp.sh
#
###############################################################################
# Send emails directly via SMTP using ssmtp
###############################################################################

smtp_check() {
  if [[ "${USE_SMTP}" == "TRUE" ]] && [[ -n "${ssmtp_cmd}" ]]; then
    sendmail_cmd="${ssmtp_cmd}"
  fi
}
