terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  required_version = ">= 1.5.0"
}

# describing variable with my key pair name
variable "kritesh_key_pair" {
  description = "AWS EC2 key pair name"
  type        = string
  default     = "key_pair_kritesh"
}

provider "aws" {
  region = "us-east-1"
}

# EXISTING DEFAULT VPC
data "aws_vpc" "default" {
  default = true
}

# Get all subnets inside the default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_security_group" "kritesh_security_group" {
  name        = "kritesh-security-group"
  description = "Security group for Jenkins, Ansible and Node servers"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Jenkins"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "kritesh-servers-sg"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# Jenkins Server
resource "aws_instance" "jenkins_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.small"

  # Use first subnet from the existing default VPC
  subnet_id = data.aws_subnets.default.ids[0]

  vpc_security_group_ids = [
    aws_security_group.kritesh_security_group.id
  ]

  key_name = var.kritesh_key_pair

  tags = {
    Name = "kritesh-jenkins-server"
  }
}

# Deployment Server
resource "aws_instance" "deployment_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.small"

  subnet_id = data.aws_subnets.default.ids[0]

  vpc_security_group_ids = [
    aws_security_group.kritesh_security_group.id
  ]

  key_name = var.kritesh_key_pair

  tags = {
    Name = "kritesh-deployment-server"
  }
}

# Ansible Controller Server
resource "aws_instance" "ansible_controller" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.small"

  subnet_id = data.aws_subnets.default.ids[0]

  vpc_security_group_ids = [
    aws_security_group.kritesh_security_group.id
  ]

  key_name = var.kritesh_key_pair

  tags = {
    Name = "kritesh-ansible-controller-server"
  }
}

# Node Server
resource "aws_instance" "node_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.small"

  subnet_id = data.aws_subnets.default.ids[0]

  vpc_security_group_ids = [
    aws_security_group.kritesh_security_group.id
  ]

  key_name = var.kritesh_key_pair

  tags = {
    Name = "kritesh-node-server"
  }
}

# OUTPUTS
output "jenkins_public_ip" {
  value = aws_instance.jenkins_server.public_ip
}

output "deploy_public_ip" {
  value = aws_instance.deployment_server
}

output "ansible_public_ip" {
  value = aws_instance.ansible_controller.public_ip
}

output "node_server_public_ips" {
  value = aws_instance.node_server.public_ip
}

output "instance_ids" {
  value = {
    jenkins    = aws_instance.jenkins_server.id
    deployment = aws_instance.deployment_server.id
    ansible    = aws_instance.ansible_controller.id
    node       = aws_instance.node_server.id
  }
}
