#!/bin/bash
#
# pmfix()
#
# Repairs potential permission issues before deployment

trace "Loading permFix()"

function permFix() {
    # Force sudo password input if needed
    sudo sleep 1    
    echo -e "${green}Setting permissions...${endColor}"

    # CAA repository still needs special treatment, /lib is obselete for future repositories
    if [ -d "$WORKPATH/$APP/lib" ]; then
    #if [ $1 = "caa" ]; then
    echo -e "  $APP/lib/"
    sudo chown -R cworrell.web /var/www/html/$APP/lib ; \
else
   sleep 1
fi

    # Set permissions
    sudo chown -R cworrell.web /var/www/html/$APP/.git ; \
    echo -e "  $APP/.git"
    sudo chown -R apache.apache /var/www/html/$APP/public/system ; \
    echo -e "  $APP/public/app/system/"
    sudo chown -R apache.apache /var/www/html/$APP/public/app ; \
    echo -e "  $APP/public/app/"
    echo ""
}