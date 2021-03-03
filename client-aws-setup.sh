#!/bin/bash

ts=$(date +%d-%m-%Y_%H-%M-%S)
pt="docker-innkeepr-server-$ts"
# Insert your AWS ID, e.g. AWSID.dkr.ecr.eu-central-1.amazonaws.com
AWS_ID=INSERT_YOUR_AWS
#e.g. eu-central-1
ECS_REGION=INSERT_YOUR_REGION
#e.g. modelapi-cluster-keypair (without ending)
KEYPAIR=INSERT_YOUR_KEYPAIR

# login to ecr and pull api images
##################################
#echo "Pull innkeepr-analyticsapi" 
#aws ecr get-login-password --region $ECS_REGION | sudo docker login --username AWS --password-stdin 576891989037.dkr.ecr.eu-central-1.amazonaws.com
#sudo docker pull 576891989037.dkr.ecr.eu-central-1.amazonaws.com/innkeepr-analyticsapi

# login to ecr and pull innkeepr server images
##############################################
echo "Pull innkeepr-server and client images" 
aws ecr get-login-password --region $ECS_REGION | sudo docker login --username AWS --password-stdin 663925627205.dkr.ecr.eu-central-1.amazonaws.com 
echo "Pull innkeepr-client"
sudo docker pull 663925627205.dkr.ecr.eu-central-1.amazonaws.com/innkeepr-client 
echo "Pull innkeepr-server"
sudo docker pull 663925627205.dkr.ecr.eu-central-1.amazonaws.com/innkeepr-server 

# create repository on aws
##########################
echo "Creatre repsoitories" 
#aws ecr create-repository --repository-name innkeepr-analyticsapi
aws ecr create-repository --repository-name innkeepr-client
aws ecr create-repository --repository-name innkeepr-server

# tag and push image (server)
####################
aws ecr get-login-password --region $ECS_REGION | sudo docker login --username AWS --password-stdin $AWS_ID
#echo "Push Image: innkeepr-analytics" 
#docker tag 576891989037.dkr.ecr.eu-central-1.amazonaws.com/innkeepr-analyticsapi $AWS_ID/innkeepr-analyticsapi:latest
#docker push $AWS_ID/innkeepr-analyticsapi:latest
echo "Push Image: innkeepr-client" 
docker tag 663925627205.dkr.ecr.eu-central-1.amazonaws.com/innkeepr-client $AWS_ID/innkeepr-client:latest
docker push $AWS_ID/innkeepr-client:latest
echo "Push Image: innkeepr-server" 
docker tag 663925627205.dkr.ecr.eu-central-1.amazonaws.com/innkeepr-server $AWS_ID/innkeepr-server:latest
docker push $AWS_ID/innkeepr-server:latest

# create cluster
####################
#echo "Create Cluster: cluster innkeepr-analyticsapi"
#ecs-cli up --force --capability-iam --instance-type m5n.large --image-id ami-0009a0c29a961a36f --launch-type EC2 --cluster ecs-cluster-innkeepr-analyticsapi --region $ECS_REGION --keypair $KEYPAIR --port 22 
echo "Create Cluster: innkeepr-client" 
ecs-cli up --force --capability-iam --instance-type t3.large --image-id ami-0e781777db20a4f7f --launch-type EC2 --cluster ecs-cluster-innkeepr-client --region $ECS_REGION --keypair $KEYPAIR --port 22 
echo "Create Cluster: innkeepr-server" 
ecs-cli up --force --capability-iam --instance-type t3.large --image-id ami-0e781777db20a4f7f --launch-type EC2 --cluster ecs-cluster-innkeepr-server --region $ECS_REGION --keypair $KEYPAIR --port 22 
echo "Sleep for 60 seconds to create instances" 
sleep 60

# create task defintion
#######################
#echo "Create Task: cluster innkeepr-analyticsapi"
#aws ecs register-task-definition --cli-input-json file://innkeepr-analyticsapi-task.json
echo "Create Task: cluster innkeepr-client" 
aws ecs register-task-definition --cli-input-json file://innkeepr-client-task.json 
echo "Create Task: cluster innkeepr-server" 
aws ecs register-task-definition --cli-input-json file://innkeepr-server-task.json 


# execute tasks in the according cluster
########################################
#echo "Run Task: cluster innkeepr-analyticsapi"
#aws ecs run-task --cluster ecs-cluster-innkeepr-analyticsapi --task-definition innkeepr-analyticsapi --count 1 --launch-type EC2
echo "Run Task: cluster innkeepr-client"
aws ecs run-task --cluster ecs-cluster-innkeepr-client --task-definition innkeepr-client --count 1 --launch-type EC2
echo "Run Task: cluster innkeepr-server"
aws ecs run-task --cluster ecs-cluster-innkeepr-server --task-definition innkeepr-server --count 1 --launch-type EC2