# Set Up Innkeepr
Steps to set up Innkeepr Sever, Client and AnaltyicsAPI on AWS. There are two ways:

## Create AWS keypair file:
Go to https://eu-central-1.console.aws.amazon.com/ec2/v2/home?region=eu-central-1#KeyPairs: and create a keypair
- name: **choose-a-name**

It is saved automatically normally in the download folder. Save the keypair file in the folder of aws-configuration-helper.

## If the aws-cli and docker is not installed, then do the following steps first

### Install prerequisites for AWS
For the next step you need the AWS Access Key and AWS Secret Access Key. If you do not already have them you can create them at AWS --> Click on the Arrow of your username --> choose Ihre Sicherheitsanmeldeinformationen --> go to Zugriffsschlüssel (Zugriffsschlüssel-ID und geheimer Zugriffsschlüssel) --> Neuen Zugriffsschlüssel erstellen.

To install prerequisites run
> sh install-prerequisites.sh

To enter during the process:
1. [sudo] Passort fuer username: Enter your sudo password
2. Configure AWS
  - AWS Access Key ID [********************]: Enter your AWS Key ID
  - AWS Secret Access Key [*******************]:  Enter your AWS Secret Access Key
  - Default region name: enter your region, e.g. eu-central-1
  - Default output format [json]: json
3. Create Docker Context
  - Choose "An Existing AWS Profile" or "AWS secret and token credentials" if first does not exist
    - if AWS secret and token credentials: enter your access keys and the region
  - default

### Set up Docker Credentials
Open docker config file:
- > cat ~/.docker/config.json

If the file does not exist , create the file
- > touch ~/.docker/config.json

If the directory ~/.docker/ does not exist run the underneath command and then try againg the touch command
> mkdir ~/.docker/

Insert the json script to the ~/.docker/config.json file & save it:
- open file with nano editor
> nano ~/.docker/config.json
- copy this to the empty file
```json
{
    "credHelpers": {
		"663925627205.dkr.ecr.eu-central-1.amazonaws.com": "ecr-login"
	}
}
```
- STRG+X --> save Yes

## Modiy client-aws-setup.sh Script
1. Replace **YOUR_AWSID** with your AWS ID
2. Enter your region into **YOUR_REGION**, e.g. eu-central-1
3. Replace **YOUR_KEYPAIR** with the name of your keypair file

## Modify json files
- innkeepr-analytics-modeling-task.json --> replace **YOURAWSID** with your AWS ID
- innkeepr-proxy-task.json --> replace **YOURAWSID** with your AWS ID
- innkeepr-client-task.json --> replace **YOURAWSID** with your AWS ID

## Run Script
> sh client-aws-setup.sh

### If creation of clusters do not work it has to be done manually
- via ECR --> Clusters --> Create Clusters
- The instance details can be found in client-aws-setup.sh

## Step 10: Set up security groups
 - innkeepr-client:
    - for testing use ***--cidr 0.0.0.0/0***, but keep in mind that it is open for everyone
    - Port 80: typ HTTP
   > aws ec2 authorize-security-group-ingress --group-id sg-***security-id*** --protocol tcp --port 80 --cidr ***cidr-address*** --region ***your-region***
    - Port 443: typ HTTPS
   > aws ec2 authorize-security-group-ingress --group-id sg-***security-id*** --protocol tcp --port 443 --cidr ***cidr-address*** --region ***your-region***
   - Port 4200
   > aws ec2 authorize-security-group-ingress --group-id sg-***security-id*** --protocol tcp --port 4200 --cidr ***cidr-address*** --region ***your-region***

 - innkeepr-proxy
    - Port 80: typ: HTTP
   > aws ec2 authorize-security-group-ingress --group-id sg-***security-id*** --protocol tcp --port 80 --cidr ***cidr-address*** --region ***your-region***
    - Ports 3000-3443
   > aws ec2 authorize-security-group-ingress --group-id sg-***security-id*** --protocol tcp --port 3000-3443 --cidr ***cidr-address*** --region ***your-region***
    - Ports 443, typ: HTTPS
  > aws ec2 authorize-security-group-ingress --group-id sg-***security-id*** --protocol tcp --port 443 --cidr ***cidr-address*** --region ***your-region***

## Now you can connect to API
The ***Oeffentlicher IPv4-DNS*** can be found in the container instance of the task running in the certain cluster, e.g. for the innkeepr-client task: AWS console --> ECR --> Clusters --> ecs-cluster-innkeepr-client  --> Tab Task --> Container Instance --> Public DNS
- innkeepr-client: ***Oeffentlicher IPv4-DNS***:80/docs

## Detach Instance from auto scaling groups
Got to EC2 -> Autoscaling groups
Do the following steps for the autoscaling groups for ecs-cluster-innkeepr-analytics and innkeepr-proxy
1. Go to the instance management tab
2. choose instance and choose the action detach
3. delete autoscaling group

## Set up Event Rule for Stopped Tasks
Got to: SNS (https://console.aws.amazon.com/sns/v3/home)
1. Create Topic for SNS (if it does not already exists)
  - Name: <customername>-aws-sns
  - Displayname: <customername>-aws-sns
  - Create Topic
2. Create Event Rule:
  - Go to CloudWatch:  https://console.aws.amazon.com/cloudwatch/
  - On the navigation pane, choose Events, Rules, Create rule.
  - Name: innkeepr-proxy-task-stopped
  - Choose Event Pattern
  - Choose Customer Pattern
    Insert
    ```json {
    "source":[
        "aws.ecs"
    ],
   "resources":[
      "arn:aws:ecs:eu-central-1:YOUR_AWSID:cluster/ecs-cluster-innkeepr-proxy"
    ],
    "detail-type":[
        "ECS Task State Change"
    ],
    "detail":{
        "lastStatus":[
          "STOPPED"
        ],
        "stoppedReason":[
          "Essential container in task exited"
        ]
    }
  }
  ```
  - Target: SNS topic
  - Topic: <customername>-aws-sns

## Set-up Logs for Load Balancer
Go to S3 Bucket innkeer-analytics
1. Create Folder: innkeepr-load-balancer-proxy
2. Add Bucket Permissions:
- for eu-central-1: may change arn:aws:iam::054676820928:root to your resource id (see: https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-access-logs.html)
```json
{
    "Version": "2012-10-17",
    "Id": "AWSConsole-AccessLogs-Policy-Innkeepr-Load-Balancer",
    "Statement": [
        {
            "Sid": "AWSConsoleStmt",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::054676820928:root"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::innkeepr-analytics/innkeepr-load-balancer-proxy/AWSLogs/YOUR_AWS_ID/*"
        },
        {
            "Sid": "AWSLogDeliveryWrite",
            "Effect": "Allow",
            "Principal": {
                "Service": "delivery.logs.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::innkeepr-analytics/innkeepr-load-balancer-proxy/AWSLogs/YOUR_AWS_ID/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        },
        {
            "Sid": "AWSLogDeliveryAclCheck",
            "Effect": "Allow",
            "Principal": {
                "Service": "delivery.logs.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "arn:aws:s3:::innkeepr-analytics"
        }
    ]
}
```

Got to EC2 --> Load Blancer
1. Choose the Innkeepr Loadbalancer
2. Edit Attributes
  - Activate Zugriffsprotokolle/Cloud Watch Logs
  - S3-Speicherort s3://innkeepr-analytics/innkeepr-load-balancer-proxy

## Handling Error Messages
- Update instance: see https://docs.aws.amazon.com/AmazonECS/latest/developerguide/agent-update-ecs-ami.html
- Error after Running Task:
    - Error response from daemon: failed to initialize logging driver: failed to create Cloudwatch log group: AccessDeniedException: User:
        1. go to IAM ROles
        2. choose Cluster Role (see your EC2 --> instances --> IAM Role is listed here)
        3. add policy as in https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/QuickStartEC2Instance.html#running-ec2-step-1
- Error setting up cluster:
  - "level=error msg="Failure event" reason="Template error: Fn::Select  cannot select nonexistent value at index 1" resourceType="AWS::EC2::Subnet"

  Solution see: https://github.com/widdix/aws-cf-templates/issues/37
    1. Check if subnets for other region exits at AWS --> VPC --> Subnets, here the regions are listed in the table
    2. If not add them, e.g.
    > sudo aws ec2 create-default-subnet --availability-zone eu-central-1b

    > sudo aws ec2 create-default-subnet --availability-zone eu-central-1c




