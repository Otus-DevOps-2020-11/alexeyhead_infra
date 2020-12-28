#!/usr/bin/env bash
# Use home dir
cd ~
# Install git
sudo apt install git -y
# Clone app from repo
git clone -b monolith https://github.com/express42/reddit.git
# Change dir and install dependencies
cd reddit && bundle install
# Deploy app
puma -d
# Check that app is running and which port is listening
ps aux | grep puma
