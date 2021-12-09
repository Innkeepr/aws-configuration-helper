# Set Up Innkeepr
Steps to set up Innkeepr Sever, Client and AnaltyicsAPI on AWS. There are two ways:

## Set Up Innkeepr on AWS Ubuntu Instance

### Step 1: Set Up AWS
#### Create AWS keypair file:
Go to https://eu-central-1.console.aws.amazon.com/ec2/v2/home?region=eu-central-1#KeyPairs: and create a keypair
- name: innkeepr-keypair

It is saved automatically normally in the download folder. Save the keypair file in the folder of aws-configuration-helper. 

#### Set Up InnkeeprEcsInstanceRole:
AWS --> IAM Role --> Create Role --> choose EC2
- Richtlinie: AmazonEC2ContainerServiceforEC2Role 
- Vertrauungsstellungen: ec2.amazonaws.com 
- name: InnkeeprEcsInstanceRole

#### Set Up InnkeeprEcsTaskExecutionRole
AWS --> IAM Role --> Create Role --> choose EC2
- name: InnkeeprEcsTaskExecutionRole
- Richtlinie: AmazonInnkeeprEcsTaskExecutionRolePolicy 
- Vertrauungsstellungen: ecs-tasks.amazonaws.com 

#### Allow the creation of logs in IAM Role InnkeeprEcsTaskExecutionRole
1. go to IAM Roles and open Roles
2. choose InnkeeprEcsTaskExecutionRole
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
8. Öffne wieder InnkeeprEcsTaskExecutionRole
9. Klicke auf Richtlinie anfügen
10. Suche nach der oben erstellen Richtlinie und füge sie an

### Step 2: Create AWS Instance
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
8. Schritt 7: Überprüfen des Instance-Starts --> click on Starten
    - choose the above created key pair file
    - click on Starten der Instance

### Step 3: Connect to Instance
#### Linux
- open the terminal and go to the folder of the keypair of Step 1
- open AWS console in Browser --> EC2 --> go to instance which was generated in Step 2 --> click on verbinden --> execute the commands to connect to the instance

#### Windows
1. Install Putty: https://www.chiark.greenend.org.uk/~sgtatham/putty/
2. Open PuttyGen
  - Parameters: Type of key to generate: RSA
  - Load File
    - choose all files
    - load your keypair .pem file
  - Save private key
  - Name it as the pem file
  - Close PutyGen
3. Open Putty
  - Category → Session
    - Host Name → DNS Puplic Hostname of the instance, e.g. my-instance-user-name@my-instance-public-dns-name
    - Port: 22
    - Connection type: SSH
    - Saved Session: Innkeepr → Save
  - Extend Connection → SSH -> Choose Auth → Browse
    - Select ppk file 
  - Click on Open
  - Putty Security Alert → Choose yes
  - In Terminal login as: ubuntu

Ausführlich: https://docs.aws.amazon.com/de_de/AWSEC2/latest/UserGuide/putty.html 

***Now you should be on your AWS Instance. The next steps has to be executed on this instance***

### Step 4: Clone aws-configuration-helper
> git clone https://github.com/Innkeepr/aws-configuration-helper.git

- go into folder aws-configuration-helper/
> cd aws-configuration-helper/

- copy keypair file from your local machine to instance. YOURACCESS can be found in AWS --> EC2 --> Instance --> Choose the instance --> use Öffentlicher IPv4-DNS

#### Linux
> scp -i innkeepr-keypair.pem innkeepr-keypair.pem ubuntu@ec2-**YOURACCESS**.eu-central-1.compute.amazonaws.com:/home/ubuntu/aws-configuration-helper

#### Windows
- Install / Open FileZilla
- Set up the server for ssh via Öffentlicher IPv4-DNS
- choose authentification via Schlüsselparameter
- Upload the innkeepr-policy-taks-role.ppk file
- Save
- Connect to Instance
- Drag File to Instance folder aws-configuration-helper

### Step 5: Install prerequisites for AWS
For the next step you need the AWS Access Key and AWS Secret Access Key. If you do not already have them you can create them at AWS --> Click on the Arrow of your username --> choose Ihre Sicherheitsanmeldeinformationen --> go to Zugriffsschlüssel (Zugriffsschlüssel-ID und geheimer Zugriffsschlüssel) --> Neuen Zugriffsschlüssel erstellen. 

To install prerequisites run
> sudo sh install-prerequisites.sh

To enter during the process:
1. [sudo] Passort fuer username: Enter your sudo password
2. Configure AWS
  - AWS Access Key ID [********************]: Enter your AWS Key ID
  - AWS Secret Access Key [*******************]:  Enter your AWS Secret Access Key
  - Default region name: enter your region, e.g. eu-central-1
  - Default output format [json]: json
3. Create Docker Context
  - Choose "An Existing AWS Profile"
  - default
  
### Step 6: Set up Docker Credentials
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
	},
}
```
- STRG+X --> save Yes

### Step 7: Set up Innkeepr Variables
In aws-configuration-helper
Preparation:
- check on AWS that you are allowed to add three new vpcs (other wise an error message will occur like "The maximum number of internet gateways has been reached"). By default 5 VPCs per region are allowed.
    - AWS Console --> VPC --> VPC Dashboard
- add variable names to client-aws-setup.sh file

> nano client-aws-setup.sh

    - include your AWSid at the top: INSERT_YOUR_AWS
    - define your AWS region: INSERT_YOUR_REGION
    - define your AWS keypair file (which your created above): INSERT_YOUR_KEYPAIR 
- innkeepr-client-task.json
  > nano innkeepr-client-task.json
  - "image": Insert YOURAWS (accout number), e.g. YOURAWS=***AWSID***
  - define your "awslogs-region" if it is not eu-central, e.g. <yourLocation>
  - STRG+X
  - Save -> Y

  Do the same for: 
- innkeepr-server-task.json
  > nano innkeepr-server-task.json

### Step 9: Set up Innkeepr Clusters

Run the script which will pull, push image, create clusters and create and run task:
> sudo sh client-aws-setup.sh $>client-aws-setup.out

This script set up the pulls and push the necessary images and set up the clusters and the according tasks:
 - cluster: ecs-cluster-innkeepr-client & task: innkeepr-client
 - cluster: ecs-cluster-innkeepr-server & task: innkeepr-server

### Step 10: Set up security groups
 - innkeepr-client:
    - for testing use ***--cidr 0.0.0.0/0***, but keep in mind that it is open for everyone
    - Port 80:
   > aws ec2 authorize-security-group-ingress --group-id sg-***security-id*** --protocol tcp --port 80 --cidr ***cidr-address*** --region ***your-region***
    - Port 443:
   > aws ec2 authorize-security-group-ingress --group-id sg-***security-id*** --protocol tcp --port 443 --cidr ***cidr-address*** --region ***your-region***
   - Port 4200
   > aws ec2 authorize-security-group-ingress --group-id sg-***security-id*** --protocol tcp --port 4200 --cidr ***cidr-address*** --region ***your-region*** 

 - innkeepr-server
    - Port 80:
   > aws ec2 authorize-security-group-ingress --group-id sg-***security-id*** --protocol tcp --port 80 --cidr ***cidr-address*** --region ***your-region***
    - Ports 3000-3443
   > aws ec2 authorize-security-group-ingress --group-id sg-***security-id*** --protocol tcp --port 3000-3443 --cidr ***cidr-address*** --region ***your-region***
    - Ports 443
  > aws ec2 authorize-security-group-ingress --group-id sg-***security-id*** --protocol tcp --port 443 --cidr ***cidr-address*** --region ***your-region***

### Step 11: Now you can connect to API
The ***Oeffentlicher IPv4-DNS*** can be found in the container instance of the task running in the certain cluster, e.g. for the innkeepr-client task: AWS console --> ECR --> Clusters --> ecs-cluster-innkeepr-client  --> Tab Task --> Container Instance --> Public DNS
- innkeepr-client: ***Oeffentlicher IPv4-DNS***:80/docs

### Step 12: Stop clusters
Each cluster has it's own auto scaling group which can be delted. If delted, the instance will stop as well.

EC2 --> Auto Scaling Groups --> Delete

### Step 13: Use EC2 Launch Konfiguration to restart clusters
The setup is saved here automatically, during setting it up choose the according vpc and subnets which were created in Step 4

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




