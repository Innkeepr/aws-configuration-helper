# Set Up Innkeepr
Steps to set up Innkeepr Sever, Client and AnaltyicsAPI on AWS

### Step 1: Set up AWS
If the AWS client, docker integration and amazon-ecr-credential-helper does not already exist run 
> sh install-prerequisites.sh


### Step 2: Set up Docker Credentials
Open docker config file: cat ~/.docker/config.json & add in config.json Innkepr ID:
```json
{
    "credHelpers":
    {
        "576891989037.dkr.ecr.eu-central-1.amazonaws.com": "ecr-login"
    } 
}
```

### Step 3: Create keypair file
https://eu-central-1.console.aws.amazon.com/ec2/v2/home?region=eu-central-1#KeyPairs:

Save the keypair file in the folder of Innkeepr-ClientAccess

### Step 4: Set up Innkeepr
Preparation:
- check on AWS that you are allowed to add three new vpcs (other wise an error message will occur like "The maximum number of internet gateways has been reached"). By default 5 VPCs per region are allowed.
    - AWS Console --> VPC --> VPC Dashboard
- add variable names to client-aws-setup.sh file
    - include your AWSid at the top
    - define your AWS region
    - define your AWS keypair file
- innkeepr-analyticsapi-task.json & innkeepr-client-task.json & innkeepr-server-task.json
    - "image": your link to repository
    - define your "awslogs-region"


Run:
>sh client-aws-setup.sh $>client-aws-setup.out

Set up Clusters and the according tasks:
 - cluster: ecs-cluster-innkeepr-analyticsapi & task: innkeepr-analyticsapi
 - cluster: ecs-cluster-innkeepr-client & task: innkeepr-client
 - cluster: ecs-cluster-innkeepr-server & task: innkeepr-server

 Note: May save the cluster outputs vpc, subnets and security groups

### Step 5: Set up security groups
 - innkeepr-analtycsapi:
   > aws ec2 authorize-security-group-ingress --group-id sg-***security-id*** --protocol tcp --port 8001 --cidr ***cidr-address*** --region ***your-region***
   - for testing use ***--cidr 0.0.0.0/0***, but keep in mind that it is open for everyone

 - innkeepr-client:
    - for testing use ***--cidr 0.0.0.0/0***, but keep in mind that it is open for everyone
   > aws ec2 authorize-security-group-ingress --group-id sg-***security-id*** --protocol tcp --port 80 --cidr ***cidr-address*** --region ***your-region***
   > aws ec2 authorize-security-group-ingress --group-id sg-***security-id*** --protocol tcp --port 443 --cidr ***cidr-address*** --region ***your-region***

 - innkeepr-server
   > aws ec2 authorize-security-group-ingress --group-id sg-***security-id*** --protocol tcp --port 80 --cidr ***cidr-address*** --region ***your-region***
   > aws ec2 authorize-security-group-ingress --group-id sg-***security-id*** --protocol tcp --port 3000-3443 --cidr ***cidr-address*** --region ***your-region***

### Step 6: Now you can connect to API
The ***Oeffentlicher IPv4-DNS*** can be found in the container instance of the task running in the certain cluster, e.g. for the innkeepr-client task: AWS console --> ECR --> Clusters --> ecs-cluster-innkeepr-client  --> Tab Task --> Container Instance --> Public DNS
- innkeepr-analyticsapi: ***Oeffentlicher IPv4-DNS***:***PORT***/docs
- innkeepr-client: ***Oeffentlicher IPv4-DNS***:80/docs

### Step 7: Stop it
EC2 --> Auto Scaling Groups --> Delete

### Step 8: Use EC2 Launch Konfiguration
The setup is saved here automatically, during setting it up choose the according vpc and subnets which were created in Step 4


## Handling Error Messages
- Update instance: see https://docs.aws.amazon.com/AmazonECS/latest/developerguide/agent-update-ecs-ami.html
- Error after Running Task:
    - Error response from daemon: failed to initialize logging driver: failed to create Cloudwatch log group: AccessDeniedException: User:
        1. go to IAM ROles
        2. choose Cluster Role (see your EC2 --> instances --> IAM Role is listed here)
        3. add policy as in https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/QuickStartEC2Instance.html#running-ec2-step-1

 # TO DO
- remove variables from client-aws-setup
- remove variables form json tasks
- test pull image from my account with willis access
- test if my image can run on smaller server --> long term
