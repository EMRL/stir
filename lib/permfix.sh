#!/bin/bash
#
# pmfix()
#
# Repairs potential permission issues before deployment
trace "Loading permFix()"

function permFix() {
  # Force sudo password input if needed
  sudo sleep 1    
  notice "Setting permissions..."    
  
  # /lib is obselete for future repositories
  if [ -d "$WORKPATH/$APP/lib" ]; then
    sudo chown -R $DEVUSER.$DEVGRP $WORKPATH/$APP/lib; #errorChk
    info "  $APP/lib/"
  else
    sleep 1
  fi

  # Set permissions
  sudo chown -R $DEVUSER.$DEVGRP $WORKPATH/$APP/.git; #errorChk
  info "  $APP/.git"
  sudo chown -R $APACHEUSER.$APACHEGRP $WORKPATH/$APP/public/system; #errorChk
  info "  $APP/public/app/system/"
  sudo chown -R $APACHEUSER.$APACHEGRP $WORKPATH/$APP/public/app; #errorChk
  info "  $APP/public/app/"
}