#!/usr/bin/env bash
#
# smtp.sh
#
###############################################################################
# Send emails directly via SMTP using ssmtp
###############################################################################

function check_smtp() {
  if [[ "${USE_SMTP}" != "TRUE" ]] || [[ -z "${ssmtp_cmd}" ]]; then
    return
  else
    sendmail_cmd="${ssmtp_cmd}"
  fi
}
