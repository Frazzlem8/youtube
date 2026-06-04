# ------- AWS VPC DHCP Option Sets - Variables -------

# -------------------- General --------------------

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "eu-west-2"
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "dhcp-demo"
}

# -------------------- Networking --------------------

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

# -------------------- DHCP Options --------------------

variable "custom_domain_name" {
  description = "Custom domain name for the DHCP option set"
  type        = string
  default     = "lab.internal"
}

variable "dns_servers" {
  description = "List of DNS server IPs (use [\"AmazonProvidedDNS\"] for AWS default resolver)"
  type        = list(string)
  default     = ["AmazonProvidedDNS"]
}

# -------------------- EC2 --------------------

variable "instance_type" {
  description = "EC2 instance type for the target instance"
  type        = string
  default     = "t3.micro"
}

variable "kali_ami_id" {
  description = "AMI ID for the Kali Linux Marketplace image (eu-west-2)"
  type        = string
  default     = "ami-0169343dd7b12ae72" # Kali Linux AMD 64-bit
}

variable "kali_instance_type" {
  description = "EC2 instance type for the Kali instance"
  type        = string
  default     = "t3.medium"
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH into the instances"
  type        = string
}
