
terraform {
  required_version = ">= 0.12"
}

# Basic aws custom networking of vpc, subnets, ecs-optimized ami, internet gateway, routes.

provider "aws" {
  region = var.PROJECT_1_AWS_REGION_1
}


resource "aws_vpc" "the_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
}


resource "aws_subnet" "the_subnet" {
  vpc_id = aws_vpc.the_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  depends_on = [aws_internet_gateway.the_igw]
  map_public_ip_on_launch = true
}


data "aws_ami" "amazon_linux_ecs" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-*-amazon-ecs-optimized"]
  }

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
}


resource "aws_internet_gateway" "the_igw" {
  vpc_id = aws_vpc.the_vpc.id
}


resource "aws_route_table" "the_route_table" {
  vpc_id = aws_vpc.the_vpc.id
}


# Make this routing table the main routing table for the vpc

resource "aws_main_route_table_association" "the_main_association" {
  vpc_id = aws_vpc.the_vpc.id
  route_table_id = aws_route_table.the_route_table.id
}


resource "aws_route_table_association" "associate_the_subnet" {
  subnet_id = aws_subnet.the_subnet.id
  route_table_id = aws_route_table.the_route_table.id
}


resource "aws_route" "route_the_igw" {
  route_table_id            = aws_route_table.the_route_table.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id		    = aws_internet_gateway.the_igw.id
}

# ECS cluster, task definition, service, launch template and security group

resource "aws_ecs_cluster" "the_cluster" {
  name = "cluster-${var.PROJECT_1_NAME}"
  setting {
    name = "containerInsights"
    value = "enabled"
  }
}


# Specify the family to find the latest active revision in that family.

data "aws_ecs_task_definition" "the_task" {
  depends_on = [aws_ecs_task_definition.the_task]
  task_definition = aws_ecs_task_definition.the_task.family
}


resource "aws_ecs_service" "the_service" {
  name = "service-${var.PROJECT_1_NAME}"
  cluster         = aws_ecs_cluster.the_cluster.arn
  desired_count = 1
  # Track the latest ACTIVE revision
  task_definition = "${aws_ecs_task_definition.the_task.family}:${max(aws_ecs_task_definition.the_task.revision, data.aws_ecs_task_definition.the_task.revision)}"
}


resource "aws_ecs_task_definition" "the_task" {
  family                   = var.task_name
  network_mode             = "bridge"
  memory                   = 512
  requires_compatibilities = ["EC2"]
  execution_role_arn       = aws_iam_role.execution.arn
  container_definitions    = <<DEFINITION
  [
    {
      "entryPoint": [
        "sh",
        "-c"
      ],
      "portMappings": [
        {
          "hostPort": 80,
          "protocol": "tcp",
          "containerPort": 3000
        }
      ],
      "command": [
        "npm start"
      ],
      "workingDirectory": "${var.PROJECT_1_WORKING_DIRECTORY}",
      "memory": 512,
      "image": "${var.PROJECT_1_IMAGE_URI}",
      "interactive": true,
      "essential": true,
      "pseudoTerminal": true,
      "name": "${var.task_name}"
    }
  ]
DEFINITION
}


resource "aws_launch_template" "the_launch" {
  name_prefix   = "prefix_${var.PROJECT_1_NAME}"
  image_id      = data.aws_ami.amazon_linux_ecs.id
  instance_type = "t2.micro"

  iam_instance_profile {
      name = "ecs-instance-profile-${var.PROJECT_1_NAME}"
  }
  
  key_name = var.PROJECT_1_KEY_NAME
  user_data = filebase64("user-data.sh")

  vpc_security_group_ids = [aws_security_group.the_security.id]
}


resource "aws_autoscaling_group" "the_asg" {
  desired_capacity   = 1
  max_size 	     = 1
  min_size	     = 1
  vpc_zone_identifier= [aws_subnet.the_subnet.id]

  launch_template {
    id      = aws_launch_template.the_launch.id
    version = "$Latest"
  }
}


resource "aws_security_group" "the_security" {
  name = "security-${var.PROJECT_1_NAME}"
  vpc_id      = aws_vpc.the_vpc.id

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "security-${var.PROJECT_1_NAME}"
  }
}

# Roles, Policies and Profiles necessary for ecs agent and instance

resource "aws_iam_role" "the_role" {
  name = "ecs-instance-role-${var.PROJECT_1_NAME}"
  path = "/ecs/"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": ["ec2.amazonaws.com"]
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}


resource "aws_iam_instance_profile" "the_profile" {
  name = "ecs-instance-profile-${var.PROJECT_1_NAME}"
  role = aws_iam_role.the_role.name
}


resource "aws_iam_role_policy_attachment" "ecs_ec2_role" {
  role = aws_iam_role.the_role.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}


resource "aws_iam_role" "execution" {
  name               = "ecs-execution-${var.PROJECT_1_NAME}"
  assume_role_policy = data.aws_iam_policy_document.assume_execution.json
}


resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


data "aws_iam_policy_document" "assume_execution" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}