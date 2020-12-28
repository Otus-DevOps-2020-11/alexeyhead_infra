#!/usr/bin/env bash
# Update apt
sudo apt update
# Install Ruby and Bundler
sudo apt install -y ruby-full ruby-bundler build-essential
# Check Ruby version
ruby -v
# Check Bundler version
bundler -v
