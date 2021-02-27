#!/bin/bash

# install unzip
sudo apt-get install unzip

# install aws cli
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# install docker + ecs integration
sudo apt-get install -y zip apt-transport-https ca-certificates curl gnupg-agent software-properties-common
curl -fsSL "https://download.docker.com/linux/ubuntu/gpg" | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io
curl -L https://raw.githubusercontent.com/docker/compose-cli/main/scripts/install/install_linux.sh | sh

# add experimental features and restart docker
sudo cp daemon.json /etc/docker/daemon.json
sudo systemctl restart docker

# run aws configure 
aws configure

# configure aws context for docker
sudo docker context create ecs innkeepr

# install amazon-ecr-credential-helper
curl https://github.com/awslabs/amazon-ecr-credential-helper
sudo apt update
sudo apt install amazon-ecr-credential-helper


