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
        info "  $APP/lib/"
        sudo chown -R $DEV.$GRP $WORKPATH/$APP/lib ; \
    else
        sleep 1
    fi

    # Set permissions
    sudo chown -R $DEV.$GRP $WORKPATH/$APP/.git ; \
    info "  $APP/.git"
    sudo chown -R $APACHEUSER.$APACHEGRP $WORKPATH/$APP/public/system ; \
    info "  $APP/public/app/system/"
    sudo chown -R $APACHEUSER.$APACHEGRP $WORKPATH/$APP/public/app ; \
    info "  $APP/public/app/"
}