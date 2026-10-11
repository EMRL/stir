#!/usr/bin/env bash
#
# assets.sh
#
###############################################################################
# Handles parsing and creating logs
###############################################################################

# Initializa needed variables
var=(AUTHOR AUTHOREMAIL AUTHORNAME GRAVATAR IMG_FILE DIGEST_WRAP)
init_loop

###############################################################################
# prepare_author_avatars()
#   Downloads avatar images for Git authors used in rendered HTML output.
################################################################################

prepare_author_avatars() {
  if [[ "${SKIP_GIT}" == "1" ]]; then
    return
  fi
  
  for AUTHOR in $(git log --pretty=format:"%ae|%an" | sort | uniq); do
    AUTHOREMAIL=$(echo $AUTHOR | cut -d\| -f1 | tr -d '[[:space:]]' | tr '[:upper:]' '[:lower:]')
    AUTHORNAME=$(echo $AUTHOR | cut -d\| -f2)
    GRAVATAR="https://gravatar.com/avatar/$(echo -n ${AUTHOREMAIL} | md5sum - | cut -d' ' -f1)?s=300"

    # Check for missing Gravatar
    if "${curl_cmd}" --output /dev/null --silent --head --fail "${GRAVATAR}"; then
      dot
    else
      GRAVATAR="https://www.gravatar.com/avatar"
    fi

    if [[ "${SCP_POST}" != "TRUE" ]]; then 
      IMG_FILE="${LOCAL_HOST_PATH}/${APP}/avatar/$AUTHORNAME.png"
    else
      #if [[ ! -d "/tmp/avatar" ]]; then
      #  umask 077 && mkdir /tmp/avatar &> /dev/null
      #fi
      IMG_FILE="${avatar_dir}/${AUTHORNAME}.png"
    fi
    "${curl_cmd}" -fso "${IMG_FILE}" "${GRAVATAR}"; dot
  done 
}
