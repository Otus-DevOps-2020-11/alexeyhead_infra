#!/usr/bin/env bash
# Update apt
sleep 40
apt update
# Install Ruby and Bundler
apt install -y ruby-full ruby-bundler build-essential
# Check Ruby version
ruby -v
# Check Bundler version
bundler -v
