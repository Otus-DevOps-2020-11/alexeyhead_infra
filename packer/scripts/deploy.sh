#!/usr/bin/env bash
# Use home dir
cd /opt
# Install git
apt install git -y
# Clone app from repo
git clone -b monolith https://github.com/express42/reddit.git
# Change dir and install dependencies
cd reddit && bundle install
# Deploy app
cp /tmp/puma.service /etc/systemd/system/puma.service
systemctl daemon-reload
systemctl start puma
systemctl enable puma
systemctl status puma
