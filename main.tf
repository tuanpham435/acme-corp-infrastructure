# main.tf
terraform {
  required_version = "~> 1.12.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Tạo VPC đơn giản
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  
  tags = {
    Name = "free-tier-vpc"
    Environment = "dev"
  }
}

# Tạo subnet public
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
  
  tags = {
    Name = "free-tier-subnet"
    Tag = "Test"
  }
}

# Tạo Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name = "free-tier-igw"
  }
}

# Tạo route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name = "free-tier-rt"
  }
}

# Thêm route cho internet gateway
resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# Liên kết route table với subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Tạo security group với cấu hình tối thiểu
resource "aws_security_group" "instance_sg" {
  name        = "free-tier-sg"
  description = "Allow SSH and HTTP"
  vpc_id      = aws_vpc.main.id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }
  
  # HTTP access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access"
  }

  # Outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "free-tier-sg"
  }
}

# Tạo EC2 instance với t2.micro (Free Tier)
resource "aws_instance" "app_server" {
  ami                    = var.ami_id
  instance_type          = "t2.micro" # Free Tier
  key_name               = var.key_name
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.instance_sg.id]
  
  # Cấu hình volume tối thiểu (8GB)
  root_block_device {
    volume_size = 8
    volume_type = "gp2"
  }

  # Script cài đặt tối thiểu
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>Hello from AWS Free Tier</h1>" > /var/www/html/index.html
  EOF
  
  tags = {
    Name = "free-tier-instance"
  }
}

# Tạo Elastic IP
resource "aws_eip" "instance_eip" {
  domain = "vpc"
  
  tags = {
    Name = "free-tier-eip"
  }
}

# Liên kết Elastic IP với EC2
resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.app_server.id
  allocation_id = aws_eip.instance_eip.id
}