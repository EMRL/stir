#!/bin/bash
#
# validate.sh
#
###############################################################################
# Check project's variables for special characters that may cause issues
###############################################################################
trace "Loading validation tests"

function validateVar() {
#!/bin/bash
# declare an array called array and define 3 vales
  array=( "${PROJNAME}" "${PROJCLIENT}" )
  for i in "${array[@]}"
  do
    if [ `expr "$i" : ".*[!@#\$%^\&*()_+].*"` -gt 0 ]; then 
      warning "Problem with value: ${i}\nCheck your project configuration, remove any special characters [!@#\$%^\&*()_+] and try again."; quietExit 
    fi
  done
}
