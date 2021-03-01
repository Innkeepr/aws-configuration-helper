#!/bin/bash

ts=$(date +%d-%m-%Y_%H-%M-%S)
pt="docker-innkeepr-server-$ts"
# Insert your AWS ID, e.g. AWSID.dkr.ecr.eu-central-1.amazonaws.com
AWS_ID=INSERT_YOUR_AWS
#e.g. eu-central-1
ECS_REGION=INSERT_YOUR_REGION
#e.g. modelapi-cluster-keypair (without ending)
KEYPAIR=INSERT_YOUR_KEYPAIR

# login to ecr
##############
aws ecr get-login-password --region $ECS_REGION
sudo docker login --username AWS --password-stdin $AWS_ID

# pull docker images
##########################
docker pull 576891989037.dkr.ecr.eu-central-1.amazonaws.com/innkeepr-analyticsapi
docker pull 663925627205.dkr.ecr.eu-central-1.amazonaws.com/innkeepr-client
docker pull 663925627205.dkr.ecr.eu-central-1.amazonaws.com/innkeepr-server

# create repository on aws
##########################
aws ecr create-repository --repository-name innkeepr-analyticsapi
aws ecr create-repository --repository-name innkeepr-client-test
aws ecr create-repository --repository-name innkeepr-server-test

# tag and push image (server)
####################
docker tag 576891989037.dkr.ecr.eu-central-1.amazonaws.com/innkeepr-analyticsapi $AWS_ID/innkeepr-analyticsapi:latest
docker push $AWS_ID/innkeepr-analyticsapi:latest
docker tag 663925627205.dkr.ecr.eu-central-1.amazonaws.com/innkeepr-client-test $AWS_ID/innkeepr-client-test:latest
docker push $AWS_ID/innkeepr-client-test:latest
docker tag 663925627205.dkr.ecr.eu-central-1.amazonaws.com/innkeepr-server-test $AWS_ID/innkeepr-server-test:latest
docker push $AWS_ID/innkeepr-server-test:latest

# create cluster
####################
ecs-cli up --force --capability-iam --instance-type m5n.large --image-id ami-0009a0c29a961a36f --launch-type EC2 --cluster ecs-cluster-innkeepr-analyticsapi --region $ECS_REGION --keypair $KEYPAIR --port 22
ecs-cli up --force --capability-iam --instance-type t3.large --image-id ami-0e781777db20a4f7f --launch-type EC2 --cluster ecs-cluster-innkeepr-client-test --region $ECS_REGION --keypair $KEYPAIR --port 22
ecs-cli up --force --capability-iam --instance-type t3.large --image-id ami-0e781777db20a4f7f --launch-type EC2 --cluster ecs-cluster-innkeepr-server-test --region $ECS_REGION --keypair $KEYPAIR --port 22

# create task defintion
#######################
aws ecs register-task-definition --cli-input-json file://innkeepr-analyticsapi-task.json
aws ecs register-task-definition --cli-input-json file://innkeepr-client-task.json
aws ecs register-task-definition --cli-input-json file://innkeepr-server-task.json


# execute tasks in the according cluster
########################################
aws ecs run-task --cluster ecs-cluster-innkeepr-analyticsapi --task-definition innkeepr-analyticsapi --count 1 --launch-type EC2
aws ecs run-task --cluster ecs-cluster-innkeepr-client-test --task-definition innkeepr-client-test --count 1 --launch-type EC2
aws ecs run-task --cluster ecs-cluster-innkeepr-server-test --task-definition innkeepr-server-test --count 1 --launch-type EC2