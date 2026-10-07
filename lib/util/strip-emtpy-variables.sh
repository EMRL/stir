###############################################################################
# strip_empty_variables()
#   Remove unresolved {{VARIABLE}} placeholders from a file.
#
# Arguments:
#   [file]    File containing placeholder values to remove
#
# Returns:
#   0         Placeholders removed successfully
#   non-zero  sed failed or the file argument was not provided
###############################################################################
strip_empty_variables() {
  local file="${1:-}"

  [[ -n "${file}" ]] || return 1

  sudo sed -i 's^{{.*}}^^g' "${file}"
}
