# CS312_MinecraftServer

## Background
This repo provides pre-made scripts for using Terraform to instantiate an AWS EC2 instance and auto-setup a Minecraft server. It starts with listing requirements for the tutorial, configuring your AWS CLI with your AWS credentials, and finally making minor changes to `minecraft-setup.sh` and `main.tf` so that your terraform deployment takes only 2 commands and your own Minecraft server can be born. 


## Requirements
1) [Terraform](https://developer.hashicorp.com/terraform/install) is installed
2) [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) is installed
3) Already have or able to create an [ssh key pair](https://www.ssh.com/academy/ssh/keygen)

## Configure AWS CLI
*If you are using AWS Learner Lab environment, ignore this section.*
1) Identify your AWS Access Key ID and AWS Secret Access Key (if applicable, may require your [AWS session token](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html) as well) [help](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html)
2) In your Terminal, run ```aws configure```
3) Enter information asked and set your preferred region (I'm using us-west-2) *for output format, you can either leave it blank or use 'json'*

## Minecraft Server File
*this repo provides a minecraft server file already - will require minor, manual changes to work*
1) Create and name your Minecraft Server .sh file (if using provided file, find "Download mincraft_server._version_.jar" [here](https://www.minecraft.net/en-us/download/server) and paste that link next to ```MINECRAFTSERVERURL=``` in _minecraft-setup.sh_)
2) Inorder for the EC2 instance to grab the file, you must upload the script to S3. In your terminal (AWS Learner Lab terminal or AWS CLI after [signing in to your AWS account](https://docs.aws.amazon.com/signin/latest/userguide/command-line-sign-in.html)) run ```aws s3 cp minecraft-setup.sh s3://<recognizable name>/scripts/<minecraft server filename>.sh```

## Deploy using Terraform
*this repo provides a ```main.tf``` already; however, you may need to make changes to it based on server hardware requirements and/or region preferences*
1) In your terminal, navigate to the location of ```main.tf```
2) Ensure your key pair path is correctly listed throughout the file (```~/.ssh/id_rsa```)
3) Edit the line ```"aws s3 cp s3://cs312-minecraft-server/scripts/minecraft-setup.sh /tmp/minecraft-setup.sh``` under ```resource "null_resource" "run_minecraft_setup" {``` so that it looks like ```"aws s3 cp s3://<your s3 bucket name>/scripts/minecraft-setup.sh /tmp/minecraft-setup.sh```
4) Run the command ```terraform init```
5) Run the command ```terraform apply```
6) This should create and setup your EC2 instance with a VPC, subnet, security group, gateway, and Elastic IP, pull your minecraft server file from your S3 bucket, and start your minecraft server file automatically *(it may take a couple of minutes for the minecraft server file to complete)*.
7) You should see output listing the IP of the EC2. This can be used to connect to in Minecraft itself (or scan using programs such as ```nmap``` at port 25565)

### Sources
- [Minecraft Server File and EC2 setup](https://aws.amazon.com/blogs/gametech/setting-up-a-minecraft-java-server-on-amazon-ec2/)
- [Creating and Uploading to AWS S3 bucket via AWS CLI](https://www.geeksforgeeks.org/how-to-upload-files-to-aws-s3-using-cli/)
- [Terraform tutorials for AWS](https://developer.hashicorp.com/terraform/tutorials/aws-get-started)
- [AWS networking with Terraform](https://www.geeksforgeeks.org/automating-aws-network-firewall-configurations-with-terraform/)