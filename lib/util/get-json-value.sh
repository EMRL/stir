###############################################################################
# get_json_value()
#   Get a value (or values) from a json file
#
# Arguments:
#   [key]         The JSON key whose value you are after
#   [occurance]   Get the value of the nth occurance of the key
#
# Example use:
#   get_json_value name
#   get_json_value name 30
#   cat tmpfile.txt | get_json_value id
#   VARIABLE="$(cat tmpfile.txt | get_json_value id 7)"
############################################################################### 
get_json_value() {
  if [[ -n "${1:-}" ]]; then
    json_key="${1}"
    json_num="${2:-}"

    if [[ -n "${json_num}" ]]; then
      awk -F"[,:}]" \
        '{for(i=1;i<=NF;i++){if($i~/'"${json_key}"'\042/){print $(i+1)}}}' |
        tr -d '"' |
        sed -n "${json_num}p"
    else
      awk -F"[,:}]" \
        '{for(i=1;i<=NF;i++){if($i~/'"${json_key}"'\042/){print $(i+1)}}}' |
        tr -d '"'
    fi
  fi
}
