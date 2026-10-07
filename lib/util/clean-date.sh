###############################################################################
# clean_date()
#   Format string containing default date format to be more readable 
#
# Arguments:
#   [date]        Date string  
#
# Example use:
#   clean_date 2021-10-29
############################################################################### 
clean_date() {
  if [[ -n "${1}" ]]; then
    cleaned_date="$(date -d ${1} +'%B %d, %Y')"
  fi
}
