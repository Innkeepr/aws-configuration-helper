#!/bin/bash

# install unzip
sudo apt-get install unzip

# install aws cli
echo "Install AWS CLI"
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# install docker + ecs integration
echo "Install Docker and ECS integration"
sudo apt-get install -y zip apt-transport-https ca-certificates curl gnupg-agent software-properties-common
curl -fsSL "https://download.docker.com/linux/ubuntu/gpg" | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io
curl -L https://raw.githubusercontent.com/docker/compose-cli/main/scripts/install/install_linux.sh | sh

# add experimental features and restart docker
echo "Restart Docker"
sudo cp daemon.json /etc/docker/daemon.json
sudo systemctl restart docker

# run aws configure 
echo "Configure AWS"
aws configure

# configure aws context for docker
echo "Create docker context"
sudo docker context create ecs innkeepr

# install amazon-ecr-credential-helper
echo "Install amazon-ecr-credential-helper"
curl https://github.com/awslabs/amazon-ecr-credential-helper
sudo apt update
sudo apt install amazon-ecr-credential-helper

# install aws ecs-cli
echo "Install aws ecs-cli"
sudo curl -Lo /usr/local/bin/ecs-cli https://amazon-ecs-cli.s3.amazonaws.com/ecs-cli-linux-amd64-latest
gpg --keyserver hkp://keys.gnupg.net --recv BCE9D9A42D51784F
curl -Lo ecs-cli.asc https://amazon-ecs-cli.s3.amazonaws.com/ecs-cli-linux-amd64-latest.asc
sudo chmod +x /usr/local/bin/ecs-cli
ecs-cli --version

