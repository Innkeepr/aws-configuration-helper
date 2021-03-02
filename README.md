# Set Up Innkeepr
Steps to set up Innkeepr Sever, Client and AnaltyicsAPI on AWS. There are two ways:
A. Locally on a linux system
B. Ona an AWS ubunt system

## A: Set up Innkeepr on a local linux instance

### Step 1: Install Docker 
Install docker if not already installed:
https://docs.docker.com/get-docker/ 

### Step 2: Create keypair file
https://eu-central-1.console.aws.amazon.com/ec2/v2/home?region=eu-central-1#KeyPairs:

Save the keypair file in the folder of Innkeepr-ClientAccess

### Step 3: Allow the creation of logs in IAM Role
1. go to IAM Roles and open Roles
2. choose ecsTaskExecutionRole
3. Richtlinie anfügen
4. Richtlinie erstellen (Details see: https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/QuickStartEC2Instance.html#running-ec2-step-1)
5. Open Tab Json and insert
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
    ],
      "Resource": [
        "*"
    ]
  }
 ]
}
```
6. Name, e.g. **innkeepr-policy-taks-role**
7. Richtlinie erstellen
8. Öffne wieder ecsTaskExecutionRole
9. Klicke auf Richtlinie anfügen
10. Suche nach der oben erstellen Richtlinie und füge sie an

### Step 4: Set up AWS
If the AWS client, docker integration and amazon-ecr-credential-helper does not already exist run 
> sh install-prerequisites.sh

To enter during the process:
1. [sudo] Passort fuer username: Enter your sudo password
2. Configure AWS
  - AWS Access Key ID [********************]: Enter your AWS Key ID
  - AWS Secret Access Key [*******************]:  Enter your AWS Secret Access Key
  - Default region name: enter your region
  - Default output format [json]: enter

### Step 5: Set up Docker Credentials
Open docker config file: 
> cat ~/.docker/config.json 

- add in config.json Innkepr ID:
```json
{
    "credHelpers": {
		"663925627205.dkr.ecr.eu-central-1.amazonaws.com": "ecr-login"
	},
	"credHelpers": {
        "576891989037.dkr.ecr.eu-central-1.amazonaws.com": "ecr-login"
       } 
}
```
### Step 6: Set up Innkeepr
In Innkeepr-ClientAccess
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
> sh client-aws-setup.sh $>client-aws-setup.out

or with sudo (depends on your sh set up)

> sudo sh client-aws-setup.sh $>client-aws-setup.out

This script set up the pulls and push the necessary images and set up the clusters and the according tasks:
 - cluster: ecs-cluster-innkeepr-analyticsapi & task: innkeepr-analyticsapi
 - cluster: ecs-cluster-innkeepr-client & task: innkeepr-client
 - cluster: ecs-cluster-innkeepr-server & task: innkeepr-server


### Step 7: Set up security groups
 - innkeepr-analtycsapi Port 8001:
   > aws ec2 authorize-security-group-ingress --group-id sg-***security-id*** --protocol tcp --port 8001 --cidr ***cidr-address*** --region ***your-region***
   - for testing use ***--cidr 0.0.0.0/0***, but keep in mind that it is open for everyone

 - innkeepr-client:
    - for testing use ***--cidr 0.0.0.0/0***, but keep in mind that it is open for everyone
    - Port 80:
   > aws ec2 authorize-security-group-ingress --group-id sg-***security-id*** --protocol tcp --port 80 --cidr ***cidr-address*** --region ***your-region***
    - Port 443:
   > aws ec2 authorize-security-group-ingress --group-id sg-***security-id*** --protocol tcp --port 443 --cidr ***cidr-address*** --region ***your-region***

 - innkeepr-server
    - Port 80:
   > aws ec2 authorize-security-group-ingress --group-id sg-***security-id*** --protocol tcp --port 80 --cidr ***cidr-address*** --region ***your-region***
    - Ports 3000-3443
   > aws ec2 authorize-security-group-ingress --group-id sg-***security-id*** --protocol tcp --port 3000-3443 --cidr ***cidr-address*** --region ***your-region***

### Step 8: Now you can connect to API
The ***Oeffentlicher IPv4-DNS*** can be found in the container instance of the task running in the certain cluster, e.g. for the innkeepr-client task: AWS console --> ECR --> Clusters --> ecs-cluster-innkeepr-client  --> Tab Task --> Container Instance --> Public DNS
- innkeepr-analyticsapi: ***Oeffentlicher IPv4-DNS***:***PORT***/docs
- innkeepr-client: ***Oeffentlicher IPv4-DNS***:80/docs

### Step 9: Stop clusters
Each cluster has it's own auto scaling group which can be delted. If delted, the instance will stop as well.

EC2 --> Auto Scaling Groups --> Delete

### Step 10: Use EC2 Launch Konfiguration to restart clusters
The setup is saved here automatically, during setting it up choose the according vpc and subnets which were created in Step 4

## B. Set Up Innkeepr on AWS Ubuntu Instance

### Step 2: Create AWS keypair file
https://eu-central-1.console.aws.amazon.com/ec2/v2/home?region=eu-central-1#KeyPairs:

Save the keypair file in the folder of Innkeepr-ClientAccess

### Step : Create AWS Instance
1. Go to AWS --> EC2 --> Instances --> Instance starten
2. Schritt 1: Instance auswählen: Search for "Ubuntu Server 20.04 LTS" and choose it
3. Schritt 2: Wählen eines Instance-Typs: t2.micro
4. Schritt 3: Konfigurieren von Instance-Details
  - Netzwerk: Choose a VPC or create a new one
  - Subnetz: Choose a subnet
  - Öffentliche IP automatisch zuweisen: Aktivieren
  - IAM Rolle: Choose ecsInstanceRole
  - click on Next
5. Schritt 4: Speicher hinzufügen --> click on next
6. Schritt 5: Tags hinzufügen --> click on next
7. Schritt 6: Configure Security Group
  - Regeln für ausgehenden Datenverkehr hinzufügen (damit Images gepullt werden können):
  TO DO ?: Typ: HTTPS  Zieladresse: 0.0.0.0/0
8. Schritt 7: Überprüfen des Instance-Starts --> click on Starten
  - choose the above created key pair file
  - click on Starten der Instance

### Step : Connect to Instance
TO DO

Now you should be on your AWS Instance. The next steps has to be executed on this instance

### Step : Clone Innkeepr-ClientAccess
git clone https://github.com/Innkeepr/Innkeepr-ClientAccess.git
- Enter your user name and pasword when necessary (to do: public or with access?)
- go into folder Innkeepr-ClientAccess
> cd Innkeepr-ClientAccess/

- copy keypair file from your local machine to instance. YOURACCESS can be found in AWS --> EC2 --> Instance --> Choose the instance --> use Öffentlicher IPv4-DNS
> scp -i modelapi-cluster-keypair.pem modelapi-cluster-keypair.pem ubuntu@ec2-**YOURACCESS**.eu-central-1.compute.amazonaws.com:/home/ubuntu/Innkeepr-ClientAccess

### Step : Install prerequisites for AWS
> sh install-prerequisites.sh

To enter during the process:
1. [sudo] Passort fuer username: Enter your sudo password
2. Configure AWS
  - AWS Access Key ID [********************]: Enter your AWS Key ID
  - AWS Secret Access Key [*******************]:  Enter your AWS Secret Access Key
  - Default region name: enter your region, e.g. eu-central-1
  - Default output format [json]: json
3. Create Docker Context
  - Choose "AWS secret and token credentials"
  - AWS Access Key ID: Enter AWS Access Key
  - AWS Secret Access key ID: Enter AWS Secret Access Key
  - Region: choose your region (as above)
  
### Step : Set up Docker Credentials
Open docker config file: 
- > cat ~/.docker/config.json 

If the file does not exist , create the file
- > touch ~/.docker/config.json 

Insert the json script to the ~/.docker/config.json file & save it:
- open file with nano editor
> nano ~/.docker/config.json
- copy this to the empty file
```json
{
    "credHelpers": {
		"663925627205.dkr.ecr.eu-central-1.amazonaws.com": "ecr-login"
	},
	"credHelpers": {
        "576891989037.dkr.ecr.eu-central-1.amazonaws.com": "ecr-login"
       } 
}
```
- STRG+X --> save Yes

### Step : Set up Innkeepr Variables
In Innkeepr-ClientAccess
Preparation:
- check on AWS that you are allowed to add three new vpcs (other wise an error message will occur like "The maximum number of internet gateways has been reached"). By default 5 VPCs per region are allowed.
    - AWS Console --> VPC --> VPC Dashboard
- add variable names to client-aws-setup.sh file

> nano client-aws-setup.sh

    - include your AWSid at the top: INSERT_YOUR_AWS
    - define your AWS region: INSERT_YOUR_REGION
    - define your AWS keypair file (which your created above): INSERT_YOUR_KEYPAIR 
- innkeepr-analyticsapi-task.json
  > nano innkeepr-analyticsapi-task.json
  - "image": Insert YOURAWS, e.g. YOURAWS=***AWSID.dkr.ecr.REGION.amazonaws.com/***
  - define your "awslogs-region", e.g. eu-central-1
  - STRG+X
  - Save -> Y

  Do the same for: 
- innkeepr-client-task.json
  > nano innkeepr-client-task.json
- innkeepr-server-task.json
  > nano innkeepr-server-task.json

### Step : Set up Innkeepr Clusters

Run the script which will pull, push image, create clusters and create and run task:
> sudo sh client-aws-setup.sh $>client-aws-setup.out

This script set up the pulls and push the necessary images and set up the clusters and the according tasks:
 - cluster: ecs-cluster-innkeepr-analyticsapi & task: innkeepr-analyticsapi
 - cluster: ecs-cluster-innkeepr-client & task: innkeepr-client
 - cluster: ecs-cluster-innkeepr-server & task: innkeepr-server

## Handling Error Messages
- Update instance: see https://docs.aws.amazon.com/AmazonECS/latest/developerguide/agent-update-ecs-ami.html
- Error after Running Task:
    - Error response from daemon: failed to initialize logging driver: failed to create Cloudwatch log group: AccessDeniedException: User:
        1. go to IAM ROles
        2. choose Cluster Role (see your EC2 --> instances --> IAM Role is listed here)
        3. add policy as in https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/QuickStartEC2Instance.html#running-ec2-step-1


### TO DO
- set up script aws cli für mac und linux
- Ausgaben einfügen für den Kunden, um Irittierungen vermeiden
- Install ecs-cli https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ECS_CLI_installation.html

