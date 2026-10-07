###############################################################################
# get_full_path()
#   Resolve absolute paths for external commands used by Stir and store them in
#   command-specific variables.
#
#   Each available command is assigned to a variable using the format:
#     ${command}_cmd
#
#   For example:
#     git_cmd="/usr/bin/git"
#     curl_cmd="/usr/bin/curl"
#     wp_cmd="/usr/local/bin/wp"
#
#   Manually configured paths for WP-CLI and Composer take precedence over
#   automatically detected command paths. SMTP configuration is also checked
#   after command discovery so the appropriate mail command can be selected.
#
# Arguments:
#   None
#
# Sets:
#   *_cmd               Absolute path for each available external command
#   wp_cmd              WP-CLI command path
#   composer_cmd        Composer command path
#
# Uses:
#   ${WP_CLI_PATH}      Optional manually configured WP-CLI path
#   ${COMPOSER_CLI_PATH}
#                       Optional manually configured Composer path
#
# Example use:
#   get_full_path
#   "${git_cmd}" status
###############################################################################
get_full_path() {
  # Get absolute paths to critical commands
  var=(cal composer curl git gitchart gnuplot grep grunt mysqlshow npm scp 
    sendmail ssh sshpass ssmtp unzip wc wget wkhtmltopdf wp xmlstarlet)

  for i in "${var[@]}" ; do
    read -r "${i}_cmd" <<< ""
    echo "${i}_cmd" > /dev/null
    if [[ -x "$(command -v ${i})" ]]; then
      eval "${i}_cmd=\"$(which ${i})\""
    fi   
  done

  # Overwrite composer and wp commands if they are manually configured
  [[ ! -z "${WP_CLI_PATH}" ]] && wp_cmd=("${WP_CLI_PATH}")
  [[ ! -z "${COMPOSER_CLI_PATH}" ]] && composer_cmd=("${COMPOSER_CLI_PATH}")

  # If the user has SMTP configured, overwrite sendmail command with ssmtp
  smtp_check
}
