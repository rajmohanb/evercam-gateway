#!/bin/bash

# Update the code base as per http://grimoire.ca/git/stop-using-git-pull-to-deploy
# This approach assumes (and requires) no local changes being made to tracked files
# We may need to think about this in terms of the config files
cd /opt/evercam/evercam-gateway
git fetch --all
git checkout --force origin/production

# Go into the Gateway app folder
cd apps/gateway

# Update dependencies and compile
yes | mix do deps.get, compile

# restart the gateway software
/etc/init.d/evercam-gateway restart
