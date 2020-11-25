#### TERRAFORM-ECS-APP
This is an example of reusable code to automate launching a docker image of a web-application (in this example, a create-react-app) into the aws cloud on an ec2(elastic compute) instance using ECS (elastic container service).  The Infrastructure As Code is given basic tests with GOSS to test the Docker image and also with Terratest to test the Terraform automation.

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
    
#### Environmental Variables
these are set on your machine to run the terraform operations  



the project directory in the docker image
      
    TF_VAR_PROJECT_1_WORKING_DIRECTORY=/home/project-name/services/front-end

the AWS key pair name    

    TF_VAR_PROJECT_1_KEY_NAME=*key-name*

the uri for the image in the repository  

    TF_VAR_PROJECT_1_IMAGE_URI=*repository-url*:latest

the AWS region   

    TF_VAR_PROJECT_1_AWS_REGION_1=us-east-1

the name of the project  

    TF_VAR_PROJECT_1_NAME=project-name

the AWS access key ID  

    AWS_ACCESS_KEY_ID=*access-key-id*

#### Installation:

clone the project into the directory of your choice  

    git clone https://github.com/advancingship/terraform-ecs-app.git
    
go to the front-end directory under cloud  

    cd project-name/cloud/prod/services/front-end/

build the image with packer  

    packer build build.json 

import the image with docker  
 
    docker import image.tar

#### Test or use the image:

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
    
#### Tag and push the image to an image repository:

then you can tag the image for an Amazon ECR repository URL like 
000123456789.dkr.ecr.us-east-1.amazonaws.com/repo-name 
where the first number is your AWS account number 

    docker tag *image-id* *repository-url*
    
if ECR needs reauthentication  

    aws ecr get-login-password --region *region-such-as-us-east-1* | docker login --username *user-name-such-as-AWS* --password-stdin *repository-url*
  
if AWS CLI needs an update  

    pip install --upgrade awscli
    
push the image to the repository  

    docker push *repository-url*
    
#### Test, Dismantle, and Launch the terraform:
  
test the terraform if desired from the cloud/test directory

    go test -v aws_ecs_terra_test.go
    
plan the launch from the cloud/prod/services/front-end directory  
 
    terraform plan
    
dismantle, typing yes when prompted if already launched  

    terraform destroy

launch, typing yes when prompted ***MONEY, CHARGES APPLY***  

    terraform apply

