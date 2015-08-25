#!/bin/bash

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Update the code base as per http://grimoire.ca/git/stop-using-git-pull-to-deploy
# This approach assumes (and requires) no local changes being made to tracked files
# We may need to think about this in terms of the config files
cd /opt/evercam/evercam-gateway
git fetch --all
git diff --exit-code origin/production

# If there are any changes
if [ $? -eq 1 ]; then

  git checkout --force origin/production

  # Go into the Gateway app folder
  cd apps/gateway

  # Update dependencies and compile
  yes | mix do deps.get, compile

  # restart the gateway software
  /etc/init.d/evercam-gateway restart

fi
