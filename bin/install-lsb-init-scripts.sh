#!/bin/bash

# Install Init Script for VPN Client
cp ../support/lsb_init_script_evercam_vpnclient /etc/init.d/evercam-vpnclient
chmod 0755 /etc/init.d/evercam-vpnclient
update-rc.d evercam-vpnclient defaults

# Install Init Script for Evercam Gateway
cp ../support/lsb_init_script_evercam_gateway /etc/init.d/evercam-gateway
chmod 0755 /etc/init.d/evercam-gateway
update-rc.d evercam-gateway defaults
