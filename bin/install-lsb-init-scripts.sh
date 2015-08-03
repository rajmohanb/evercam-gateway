#!/bin/bash

# Install Init Script for VPN Client
cp support/lsb_init_script_evercam_vpnclient /etc/init.d/evercam-vpnclient
chmod 0755 /etc/init.d/evercam-vpnclient


# Install Init Script for Evercam Gateway
cp support/lsb_init_script_evercam_gateway /etc/init.d/evercam-gateway
chmod 0755 /etc/init.d/evercam-gateway

# Documentation about which method (update-rc.d or insserv) works is vague
# For now we're running both until we figure out. For example update-rc.d
# works on Raspbian and Debian Wheezy, but seems not to actually work
# correctly on Debian 8. This may be due to errors on our part. Needs testing
update-rc.d evercam-vpnclient defaults
update-rc.d evercam-gateway defaults
insserv evercam-vpnclient
insserv evercam-gateway
