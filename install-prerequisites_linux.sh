#!/bin/bash

# install unzip
sudo yum install unzip

# install aws cli
echo "Install AWS CLI"
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo yum install unzip
unzip awscliv2.zip
sudo ./aws/install

# install docker + ecs integration
echo "Install Docker and ECS integration"
sudo yum install -y ecs-init

# start docker
sudo service docker start

# run aws configure
echo "Configure AWS"
aws configure

# install amazon-ecr-credential-helper
echo "Install amazon-ecr-credential-helper"
curl https://github.com/awslabs/amazon-ecr-credential-helper
sudo yum update
sudo yum install amazon-ecr-credential-helper

# install aws ecs-cli
echo "Install aws ecs-cli"
sudo curl -Lo /usr/local/bin/ecs-cli https://amazon-ecs-cli.s3.amazonaws.com/ecs-cli-linux-amd64-latest
gpg --keyserver hkp://keys.gnupg.net --recv BCE9D9A42D51784F
curl -Lo ecs-cli.asc https://amazon-ecs-cli.s3.amazonaws.com/ecs-cli-linux-amd64-latest.asc
sudo chmod +x /usr/local/bin/ecs-cli
ecs-cli --version
sudo yum update



