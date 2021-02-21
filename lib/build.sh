#!/usr/bin/env bash
#
# package-manager
#
###############################################################################
# Checks if project uses node.js or grunt, and builds assets if needed. 
###############################################################################

# Initialize variables
var=(deploy_config SKIP_BUILD npm_json)
init_loop

function build_check() {
  if [[ "${FORCE}" != "1" || "${BUILD}" == "1" ]] && [[ "${UPGRADE}" != "1" ]]; then
    build_grunt   # Grunt check
    build_npm     # node.js check
  fi
}

function build_mina() {
  if [[ "${DEPLOY}" == *"mina"* ]]; then
    # Trying this a weirdo way, turn it into a loop or something later
    [[ -f "${APP_PATH}/Minafile" ]] && deploy_config="$(cat ${APP_PATH}/Minafile)"
    if [[ "${deploy_config}" =~ "npm run build" ]] && [[ "${BUILD}" != "1" ]]; then
      SKIP_BUILD="1"
    fi
  fi
}

function build_grunt() {
  # Checking for app/lib, which assumes we're using Grunt
  [[ -z "${grunt_cmd}" ]] && return

  if [[ -f "${APP_PATH}/Gruntfile.coffee" ]]; then
    notice "Found grunt configuration!" 
  else
    if  [[ "${FORCE}" = "1" ]] || yesno --default no "Build assets? [y/N] "; then
      cd "${APP_PATH}" || error_check     
      "${grunt_cmd}" build --force &>> "${trash_file}" & spinner $!
      info "Packages successfully built."
    fi
  fi
}

function build_npm() {
  [[ -z "${npm_cmd}" ]] && return
  
  if [[ -f "${APP_PATH}/${WP_ROOT}${WP_APP}/themes/site/package.json" ]]; then
    trace "${APP_PATH}/${WP_ROOT}${WP_APP}/themes/site/package.json found."
    npm_json="${APP_PATH}/${WP_ROOT}${WP_APP}/themes/site"
  elif [[ -f "${APP_PATH}/${WP_ROOT}${WP_APP}/themes/${APP}/package.json" ]]; then
    trace "${APP_PATH}/${WP_ROOT}${WP_APP}/themes/${APP}/package.json found."
    npm_json="${APP_PATH}/${WP_ROOT}${WP_APP}/themes/${APP}"
  elif [[ -f "${APP_PATH}//package.json" ]]; then
    trace "${APP_PATH}//package.json found."
    npm_json="${APP_PATH}"
  fi

  # This is so dumb
  [[ -z "${npm_json}" ]] && return
  
  build_mina

  if [[ "${SKIP_BUILD}" == "1" ]]; then
    return
  fi
   
  notice "Found npm configuration!"
  if [[ "${BUILD}" = "1" ]] || yesno --default no "Build assets? [y/N] "; then
    cd "${npm_json}" || error_check
    if [[ "${VERBOSE}" == "TRUE" ]]; then
      "${npm_cmd}" run build | tee --append "${trash_file}"               
    else
      "${npm_cmd}" run build &>> "${trash_file}"; error_check
      info "Packages successfully built."
    fi
  fi
}
