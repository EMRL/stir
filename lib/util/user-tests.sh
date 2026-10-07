#!/usr/bin/env bash
#
# user-tests.sh

###############################################################################
# user_tests()
#   Run user-requested diagnostic, integration, and configuration tests.
#
#   This function acts as the central dispatcher for Stir's command-line test
#   flags. When a supported test flag is enabled, the corresponding test
#   function is called and Stir exits cleanly afterward.
#
#   Supported tests and actions include:
#     - Display current Stir settings
#     - Test Slack integration
#     - Test webhook POST integration
#     - Test email delivery
#     - Test Google Analytics authentication
#     - Test GA4 reporting
#     - Test server monitoring
#     - Test Bugsnag integration
#     - Test Mautic integration
#     - Test OpenProject integration
#     - Test Dropbox backup access
#     - Test SSH key authentication
#
#   SSH testing is skipped when the current project does not use SSH keys or
#   when SSH checking has been explicitly disabled.
#
# Arguments:
#   None
#
# Uses:
#   ${SHOW_SETTINGS}       Display current Stir configuration
#   ${TEST_SLACK}          Run Slack integration test
#   ${TEST_WEBHOOK}        Run webhook integration test
#   ${TEST_EMAIL}          Run email delivery test
#   ${TEST_ANALYTICS}      Run Google Analytics authentication test
#   ${TEST_GA4}            Run GA4 reporting test
#   ${TEST_MONITOR}        Run server monitoring test
#   ${TEST_BUGSNAG}        Run Bugsnag integration test
#   ${TEST_MAUTIC}         Run Mautic integration test
#   ${TEST_OPENPROJECT}    Run OpenProject integration test
#   ${TEST_BACKUP}        Run Dropbox backup authentication check
#   ${TEST_SSH}            Run SSH authentication test
#   ${NO_KEY}              Indicates the project does not use SSH keys
#   ${DISABLE_SSH_CHECK}   Disables SSH authentication checks
#
# Returns:
#   Calls quiet_exit() after handling a requested test or settings action.
#   Returns normally when no supported test flag is enabled.
#
# Example use:
#   user_tests
###############################################################################
user_tests() {
  if [[ "${SHOW_SETTINGS}" == "1" ]]; then
    show_settings
    quiet_exit
  fi

  # Slack test
  if [[ "${TEST_SLACK}" == "1" ]]; then
    slack_test
    quiet_exit
  fi

  # Webhook POST test
  if [[ "${TEST_WEBHOOK}" == "1" ]]; then
    webhook_test
    quiet_exit
  fi

  # Email test
  if [[ "${TEST_EMAIL}" == "1" ]]; then
    email_test
    quiet_exit
  fi

  # Test analytics authentication
  if [[ "${TEST_ANALYTICS}" == "1" ]]; then
    ga_test
    quiet_exit
  fi

  # Test GA4 reporting
  if [[ "${TEST_GA4}" == "1" ]]; then
    ga4_test
    quiet_exit
  fi

  # Test server monitoring
  if [[ "${TEST_MONITOR}" == "1" ]]; then
    server_monitor_test
    quiet_exit
  fi

  # Test Bugsnag integration
  if [[ "${TEST_BUGSNAG}" == "1" ]]; then
    bs_test
    quiet_exit
  fi

  # Test Mautic integration
  if [[ "${TEST_MAUTIC}" == "1" ]]; then
    mtc_test
    quiet_exit
  fi

  # Test OpenProject integration
  if [[ "${TEST_OPENPROJECT}" == "1" ]]; then
    op_test
    quiet_exit
  fi

  # Test Dropbox backup authentication
  if [[ "${TEST_BACKUP}" == "1" ]]; then
    test_backup
    quiet_exit
  fi

  # Test SSH key authentication
  if [[ "${TEST_SSH}" == "1" ]]; then
    if [[ "${NO_KEY}" != "TRUE" ]] &&
       [[ "${DISABLE_SSH_CHECK}" != "TRUE" ]]; then
      notice "Checking SSH Configuration..."
      ssh_check
    else
      warning "This project is not configured to use SSH keys, no check needed."
    fi
    quiet_exit
  fi
}
