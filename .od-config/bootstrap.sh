#!/bin/bash -e

echo "installing node"

# delete .profile, which seems to confuse nvm
rm -f /root/.profile

# install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash

# use nvm in this script
. /root/.nvm/nvm.sh

# install nodejs at v16
# we're on a too-old version of Ubuntu that may not be compatible with node 18
nvm install 16.16.0

# install yarn
npm install --global yarn

echo "installing npm deps"
yarn

echo "installing services"
SERVICES=$(ls .od-config/systemd-services)
for SERVICE in $SERVICES; do
    ln -sf "/project/.od-config/systemd-services/$SERVICE" /etc/systemd/system/
done

# systemd recognize services
systemctl daemon-reload

# enable services
for SERVICE in $SERVICES; do
    systemctl enable "$SERVICE"
    systemctl start "$SERVICE"
done

echo "waiting for devservers to come up"
# TODO do this via systemd health checks
wait-for-url() {
    timeout --foreground -s TERM 30s bash -c \
        'while [[ "$(curl -s -o /dev/null -m 3 -L -w ''%{http_code}'' ${0})" != "200" ]];\
        do sleep 1;\
        done' ${1}
}

# next dev server
wait-for-url "http://localhost:3000"

