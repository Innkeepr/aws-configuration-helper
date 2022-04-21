#!/bin/bash

ts=$(date +%d-%m-%Y_%H-%M-%S)
pt="docker-innkeepr-server-$ts"
# Insert your AWS ID, e.g. AWSID.dkr.ecr.eu-central-1.amazonaws.com
AWS_ID=YOUR_AWSID
#e.g. eu-central-1
ECS_REGION=YOUR_REGION
#e.g. modelapi-cluster-keypair (without ending)
KEYPAIR=YOUR_KEYPAIR

# login to ecr and pull analytics images
##################################
echo "Pull innkeepr-analytics-modeling"
aws ecr get-login-password --region $ECS_REGION | sudo docker login --username AWS --password-stdin 663925627205.dkr.ecr.eu-central-1.amazonaws.com
sudo docker pull 663925627205.dkr.ecr.eu-central-1.amazonaws.com/innkeepr-analytics-modeling

# login to ecr and pull innkeepr proxy and client images
##############################################
echo "Pull innkeepr-proxy and client images"
aws ecr get-login-password --region $ECS_REGION | sudo docker login --username AWS --password-stdin 663925627205.dkr.ecr.eu-central-1.amazonaws.com
echo "Pull innkeepr-analytics-modeling"
sudo docker pull 663925627205.dkr.ecr.eu-central-1.amazonaws.com/innkeepr-analytics-modeling
echo "Pull innkeepr-client"
sudo docker pull 663925627205.dkr.ecr.eu-central-1.amazonaws.com/innkeepr-client
echo "Pull innkeepr-proxy"
sudo docker pull 663925627205.dkr.ecr.eu-central-1.amazonaws.com/innkeepr-proxy

# create repository on aws
##########################
echo "Creatre repsoitories"
aws ecr create-repository --repository-name innkeepr-client
aws ecr create-repository --repository-name innkeepr-proxy
aws ecr create-repository --repository-name innkeepr-analytics-modeling

# tag and push image (server)
####################
aws ecr get-login-password --region $ECS_REGION | sudo docker login --username AWS --password-stdin $AWS_ID
echo "Push Image: innkeepr-analytics-modeling"

echo "Push Image: innkeepr-client"
docker tag 663925627205.dkr.ecr.eu-central-1.amazonaws.com/innkeepr-client $AWS_ID.dkr.ecr.eu-central-1.amazonaws.com/innkeepr-client:latest
docker push $AWS_ID.dkr.ecr.eu-central-1.amazonaws.com/innkeepr-client:latest
echo "Push Image: innkeepr-proxy"
docker tag 663925627205.dkr.ecr.eu-central-1.amazonaws.com/innkeepr-proxy $AWS_ID.dkr.ecr.eu-central-1.amazonaws.com/innkeepr-proxy:latest
docker push $AWS_ID.dkr.ecr.eu-central-1.amazonaws.com/innkeepr-proxy:latest
echo "Push Image: innkeepr-analytics-modeling"
aws ecr get-login-password --region $ECS_REGION | sudo docker login --username AWS --password-stdin $AWS_ID
docker tag 663925627205.dkr.ecr.eu-central-1.amazonaws.com/innkeepr-analytics-modeling $AWS_ID.dkr.ecr.eu-central-1.amazonaws.com/innkeepr-analytics-modeling:latest
docker push $AWS_ID.dkr.ecr.eu-central-1.amazonaws.com/innkeepr-analytics-modeling:latest

# create cluster
####################
echo "Create Cluster: cluster innkeepr-analytics"
ecs-cli up --force --capability-iam --instance-type t2.2xlarge --image-id ami-0dc66d9ab40653776 --launch-type EC2 --cluster ecs-cluster-innkeepr-analytics --region $ECS_REGION --keypair $KEYPAIR --port 22
echo "Create Cluster: innkeepr-client"
ecs-cli up --force --capability-iam --instance-type t3.medium --image-id ami-0e8f6957a4eb67446 --launch-type EC2 --cluster ecs-cluster-innkeepr-client --region $ECS_REGION --keypair $KEYPAIR --port 22
echo "Create Cluster: innkeepr-proxy"
ecs-cli up --force --capability-iam --instance-type t2.micro --image-id ami-0e781777db20a4f7f --launch-type EC2 --cluster ecs-cluster-innkeepr-proxy --region $ECS_REGION --keypair $KEYPAIR --port 22
echo "Sleep for 60 seconds to create instances"
sleep 60

# create task defintion
#######################
#echo "Create Task: cluster innkeepr-analyticsapi"
aws ecs register-task-definition --cli-input-json file://innkeepr-analytics-modeling-task.json
echo "Create Task: cluster innkeepr-client"
aws ecs register-task-definition --cli-input-json file://innkeepr-client-task.json
#echo "Create Task: cluster innkeepr-server"
#aws ecs register-task-definition --cli-input-json file://innkeepr-server-task.json
echo "Create Task: cluster innkeepr-proxy"
aws ecs register-task-definition --cli-input-json file://innkeepr-proxy-task.json


# execute tasks in the according cluster
########################################
#echo "Run Task: cluster innkeepr-analyticsapi"
#aws ecs run-task --cluster ecs-cluster-innkeepr-analytics --task-definition innkeepr-analyticsapi --count 1 --launch-type EC2
#echo "Run Task: cluster innkeepr-client"
#aws ecs run-task --cluster ecs-cluster-innkeepr-client --task-definition innkeepr-client --count 1 --launch-type EC2
#echo "Run Task: cluster innkeepr-server"
#aws ecs run-task --cluster ecs-cluster-innkeepr-server --task-definition innkeepr-server --count 1 --launch-type EC2
#echo "Run Task: cluster innkeepr-proxy"
#aws ecs run-task --cluster ecs-cluster-innkeepr-proxy --task-definition innkeepr-proxy --count 1 --launch-type EC2
