#!/usr/bin/env bash
#
# report.sh
#
###############################################################################
# Handles parsing and creating monthly work reports
###############################################################################

# Initialize variables
var=(current_month current_year previous_month previous_year last_day)
init_loop

function create_report() {

  # Make sure we've got cal, or don't bother
  if [[ -z "${cal_cmd}" ]]; then
    console "Creating reports requires the cal utility which cannot be found."; quiet_exit
  fi

  message_state="REPORT"
  html_dir

  # Get the first and last day of last month
  current_month="$(date +%m)"
  current_year="$(date +%Y)"

  # Remove leading 0
  current_month="$(sed 's/^0*//' <<< $current_month)"

  if [[ "${current_month}" -eq 1 ]]; then
    previous_month="11"
    previous_year=`expr "${current_year}" - 1`
  elif [[ "${current_month}" -eq 2 ]]; then
    previous_month="12"
    previous_year=`expr "${current_year}" - 1`
  else previous_month=`expr "${current_month}" - 2`
    previous_year="${current_year}"
  fi

  if [[ "${previous_month}" -lt 10 ]];
    then previous_month="0${previous_month}"
  fi

  # Try to setup the month/day count
  last_day=`${cal_cmd} ${previous_month} ${previous_year} | egrep -a "28|29|30|31" |tail -1 |awk '{print $NF}'`

  if [[ -n "${INCLUDEHOSTING}" ]] && [[ "${INCLUDEHOSTING}" != "FALSE" ]]; then
    # If INCLUDEHOSTING is equal to something other than TRUE (And not FALSE), 
    # its value will be used as the text string in the report 
    if [[ "${INCLUDEHOSTING}" == "TRUE" ]]; then
      INCLUDEHOSTING="Web hosting for the month of ${last_month}"
    fi
    echo "<tr class=\"item-row\"><td class=\"item-name\"><div class=\"delete-wpr\">${TASK}<a class=\"delete\" href=\"javascript:;\" title=\"Remove row\">X</a></div></td><td class=\"description\"><div contenteditable class=\"editable\">${INCLUDEHOSTING}</div></td></tr>" >> "${stat_file}"
  fi

  trace "git log --all --no-merges --first-parent --before=\"${current_year}-${current_month}-1 00:00\" --after=\"${previous_year}-${previous_month}-${last_day} 00:00\" --pretty=format:\"<tr class=\"item-row\"><td class=\"item-name\"><div class=\"delete-wpr\">%h<a class=\"delete\" href=\"javascript:;\" title=\"Remove row\">X</a></div></td><td class=\"description\"><div contenteditable class=\"editable\">%s</div></td></tr>\""
  git log --all --no-merges --first-parent --before="${current_year}-${current_month}-1 00:00" --after="${previous_year}-${previous_month}-${last_day} 00:00" --pretty=format:"<tr class=\"item-row\"><td class=\"item-name\"><div class=\"delete-wpr\">%h<a class=\"delete\" href=\"javascript:;\" title=\"Remove row\">X</a></div></td><td class=\"description\"><div contenteditable class=\"editable\">%s</div></td></tr>" >> "${stat_file}"

  # If it's an empty report, this empty row will keep the javascript from breaking. Kludgy I know.
  if [[ ! -s "${stat_file}" ]]; then
    echo "<tr class=\"item-row\" id=\"hiderow\" style=\"display: none;\"><td></td><td></td></tr>" > "${stat_file}"
  fi

  # Compile full report 
  cat "${stir_path}/html/${HTMLTEMPLATE}/report/header.html" "${stat_file}" "${stir_path}/html/${HTMLTEMPLATE}/report/footer.html" > "${htmlFile}"

  # Filter and replace template variables
  process_html
}
