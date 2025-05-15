# variables.tf
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1" # Region thường có nhiều AMI Free Tier
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
  default     = "ami-06c68f701d8090592" # Amazon Linux 2023 AMI cho us-east-1
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
}