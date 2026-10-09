# variables.tf
# Define all configurable inputs for the project

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Prefix name for resources"
  type        = string
  default     = "aws-3tier-flask"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "List of CIDRs for public subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.3.0/24"]
}

variable "private_app_subnet_cidrs" {
  description = "List of CIDRs for private app subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.2.0/24", "10.0.4.0/24"]
}

variable "private_db_subnet_cidrs" {
  description = "List of CIDRs for private DB subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.5.0/24", "10.0.6.0/24"]
}

variable "instance_type" {
  description = "EC2 instance type for web and app servers"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Name of existing EC2 key pair in the region (leave blank for no SSH)"
  type        = string
  default     = ""
}

variable "db_username" {
  description = "Database admin username"
  type        = string
  default     = "flask_admin"
}

variable "db_password" {
  description = "Database admin password (provide via terraform.tfvars or TF_VAR_db_password)"
  type        = string
  sensitive   = true
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to SSH (your IP with /32). Use 0.0.0.0/0 only for learning (not recommended)."
  type        = string
  default     = "0.0.0.0/0"
}
