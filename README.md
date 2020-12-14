#### TERRAFORM-ECS-APP
This project contains an fully-functioning minimal implementation of reusable code that automates the provisioning of a docker image of a web-application and launching it into the AWS cloud on an ec2 (Elastic Compute) instance using ECS (Elastic Container Service).  The provided web-app is same operational but featureless app one gets from running 'npx create-react-app front-end'.  The Infrastructure As Code is given basic tests with Goss to test the Docker image and also with Terratest to test the Terraform automation.

If you would like to use something other than React for your app, replace the shell commands for installing libraries, nvm, node, npm and npx in the provisioners block in /cloud/prod/services/front-end/build.json with commands to install the libraries, languages and frameworks of your choosing.

If you choose to change the name of the project from "project-name" to something else, you must change it in the build.json and user-data.sh files in /cloud/prod/services/front-end as well as in /cloud/test/goss.yaml

#### Key
in any code following, any text with a star to the left and right such as  
   
    *text-here*   

indicates that you would provide a value where the stars and text would be
#### Requirements:

the following steps were tested with   

terraform v0.12.19  
goss v0.3.10  
packer 1.5.4  
docker 19.03.13, build 4484c46d9d  
python 3.7.4 for pip  
pip 20.1.1 to install AWS CLI  
an AWS account ***WHICH REQUIRES MONEY*** for uses such as launching and hosting    
aws-cli/1.18.102 Python/3.7.4 Linux/5.4.0-51-generic botocore/1.17.25  
environmental variables as follows  
    
#### Home Environment and Environmental Variables
These variables are set on your home environment (the OS on the physical machine you use for development) to run the terraform operations. On Linux and Mac OS, this is generally done using shell commands on the command line in a terminal window.  Given one wants to set a variable, "THE_VARIABLE" to the value, "the_value" the command is commonly:

    export THE_VARIABLE=the_value

In order to have this variable exist as such every time one opens a terminal window, it is common to add such commands to the one's startup shell script in one's home directory.  The shell recognizes "~" as the home directory, so if one's username on one's home environment is "the_user" and they change the current directory with the command, "cd ~", on Ubuntu, they will find themselves in /home/the_user, and on Mac they will be found in /Users/the_user.  One may find or create a startup shell script file ~/.bashrc on Ubuntu, or ~/.bash_profile on Mac Os, assuming one's shell is Bash.

It is recommended that one adds export commands for the following variables to their startup shell script:  

the project directory in the docker image
      
    TF_VAR_PROJECT_1_WORKING_DIRECTORY=/home/project-name/services/front-end

the AWS key pair name    

    TF_VAR_PROJECT_1_KEY_NAME=*key-name*

the URI for the image in the repository  

    TF_VAR_PROJECT_1_IMAGE_URI=*repository-url*:latest

the AWS region   

    TF_VAR_PROJECT_1_AWS_REGION_1=us-east-1

the name of the project  

    TF_VAR_PROJECT_1_NAME=project-name

the AWS access key ID  

    AWS_ACCESS_KEY_ID=*access-key-id*

#### Installation (shell commands):

clone the project into the directory of your choice  

    git clone https://github.com/advancingship/terraform-ecs-app.git
    
go to the front-end directory under cloud  

    cd project-name/cloud/prod/services/front-end/

build the image with packer  

    packer build build.json 

import the image with docker  
 
    docker import image.tar

#### Test or use the image (shell commands on home environment or on ec2 instance.  Docker commands are not for use when in the container):

copy the latest image ID from the output of docker images.  
use 'sec' if imported less than a minute ago, 'min' if under an hour, etc.  
 
    docker images | grep sec
    
enter a bash shell in a container of the image if desired  

     docker run -it *image-id* bash

in the shell, go to the project directory  

    cd /home/project-name/services/front-end/
    
test the project if desired, exiting by typing 'q'  

    npm test
  
run the project if desired, exiting with ctrl-c  

    npm start
    
exit the container if entered  

    exit
    
#### Tag and push the image to an image repository (home environment shell commands):

then you can tag the image for an Amazon ECR repository URL like 
000123456789.dkr.ecr.us-east-1.amazonaws.com/repo-name 
where the first number is your AWS account number 

    docker tag *image-id* *repository-url*
    
if ECR needs reauthentication (the previous command will tell you so)

    aws ecr get-login-password --region *region-such-as-us-east-1* | docker login --username *user-name-such-as-AWS* --password-stdin *repository-url*
  
if AWS CLI needs an update (it might if something isn't working with AWS)

    pip install --upgrade awscli
    
push the image to the repository  (the ECS task gets the image from there)

    docker push *repository-url*
    
#### Test, Dismantle, and Launch the terraform (home environment shell commands):
  
test the terraform if desired (from the cloud/test directory)

    go test -v aws_ecs_terra_test.go
    
plan the launch (from the cloud/prod/services/front-end directory)  
 
    terraform plan
    
dismantle what was launched (from the cloud/prod/services/front-end directory), typing yes when prompted if already launched  

    terraform destroy

launch (from the cloud/prod/services/front-end directory), typing yes when prompted ***MONEY, CHARGES APPLY***  

    terraform apply

