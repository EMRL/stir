#!/bin/bash
#
# pmfix()
#
# Repairs potential permission issues before deployment

echo "DEBUG: Loading pmfix()"

function pmfix() {
    # Force sudo password input if needed
    sudo sleep 1    
        echo -e "${green}Setting permissions...${endColor}"

    # CAA repository still needs special treatment, /lib is obselete for future repositories
    if [ -d "$WORKPATH/$SITE/lib" ]; then
    #if [ $1 = "caa" ]; then
    	echo -e "  $SITE/lib/"
    	sudo chown -R cworrell.web /var/www/html/$SITE/lib ; \
    else
    	sleep 1
    fi

    # Set Permissions
    sudo chown -R cworrell.web /var/www/html/$SITE/.git ; \
        echo -e "  $SITE/.git"
	sudo chown -R apache.apache /var/www/html/$SITE/public/system ; \
	   echo -e "  $SITE/public/app/system/"
	sudo chown -R apache.apache /var/www/html/$SITE/public/app ; \
	   echo -e "  $SITE/public/app/"
	   echo ""
}