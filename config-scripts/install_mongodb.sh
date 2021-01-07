#!/usr/bin/env bash
sudo apt update
#sudo apt install apt-transport-https ca-certificates -y
# Add key for MongoDB
wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | sudo apt-key add -
# Add MongoDB repo
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/4.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.2.list
# install MongoDB
sudo apt update
sudo apt install -y mongodb-org
# start, enable and check MongoDB
sudo systemctl start mongod
sudo systemctl enable mongod
sudo systemctl status mongod
