#Initialize Terraform
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS provider
provider "aws" {
  region = "ap-south-1"
}
# Creating a VPC
resource "aws_vpc" "assignment-vpc" {
 cidr_block = "10.0.0.0/16"
}

# Create an Internet Gateway
resource "aws_internet_gateway" "assignment-ig" {
 vpc_id = aws_vpc.assignment-vpc.id
 tags = {
 Name = "assignmentgateway1"
 }
}

# Setting up the route table
resource "aws_route_table" "assignment-rt" {
 vpc_id = aws_vpc.assignment-vpc.id
 route {
 # pointing to the internet
 cidr_block = "0.0.0.0/0"
 gateway_id = aws_internet_gateway.assignment-ig.id
 }
 route {
 ipv6_cidr_block = "::/0"
 gateway_id = aws_internet_gateway.assignment-ig.id
 }
 tags = {
 Name = "assgnrt"
 }
}

# Setting up the subnet
resource "aws_subnet" "assignment-subnet" {
 vpc_id = aws_vpc.assignment-vpc.id
 cidr_block = "10.0.1.0/24"
 availability_zone = "ap-south-1b"
 tags = {
 Name = "subnet2"
 }
}

# Associating the subnet with the route table
resource "aws_route_table_association" "assignment-rt-sub-assoc" {
subnet_id = aws_subnet.assignment-subnet.id
route_table_id = aws_route_table.assignment-rt.id
}

# Creating a Security Group
resource "aws_security_group" "assignment-sg" {
 name = "assignment-sg"
 description = "Enable web traffic for the project"
 vpc_id = aws_vpc.assignment-vpc.id
 ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
 ingress {
 description = "HTTPS traffic"
 from_port = 443
 to_port = 443
 protocol = "tcp"
 cidr_blocks = ["0.0.0.0/0"]
 }
 ingress {
 description = "HTTP traffic"
 from_port = 0
 to_port = 65000
 protocol = "tcp"
 cidr_blocks = ["0.0.0.0/0"]
 }
 ingress {
 description = "Allow port 80 inbound"
 from_port   = 80
 to_port     = 80
 protocol    = "tcp"
 cidr_blocks = ["0.0.0.0/0"]
  }
 egress {
 from_port = 0
 to_port = 0
 protocol = "-1"
 cidr_blocks = ["0.0.0.0/0"]
 ipv6_cidr_blocks = ["::/0"]
 }
 tags = {
 Name = "assignment-sg2"
 }
}

# Creating a new network interface
resource "aws_network_interface" "assignment-ni" {
 subnet_id = aws_subnet.assignment-subnet.id
 private_ips = ["10.0.1.10"]
 security_groups = [aws_security_group.assignment-sg.id]
}

# Attaching an elastic IP to the network interface
resource "aws_eip" "assignment-eip" {
 vpc = true
 network_interface = aws_network_interface.assignment-ni.id
 associate_with_private_ip = "10.0.1.10"
}


# Creating an ubuntu EC2 instance
resource "aws_instance" "Prod-Server" {
 ami = "ami-0287a05f0ef0e9d9a"
 instance_type = "t2.micro"
 availability_zone = "ap-south-1b"
 key_name = "assignmentaws1"
 network_interface {
 device_index = 0
 network_interface_id = aws_network_interface.assignment-ni.id
 }
 user_data  = <<-EOF
 #!/bin/bash
     sudo apt-get update -y
     sudo apt install docker.io -y
     sudo systemctl enable docker 
     sudo docker run -itd -p 8087:8081 aniketvishe/bankingandfinanceproject:1.0
     sudo docker start $(docker ps -aq)
 EOF
 tags = {
 Name = "Prod-Server"
 }
}
