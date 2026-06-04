# -------------------------------------------------------
# Deploy a Kali Linux Machine in AWS - Variables
# -------------------------------------------------------

# -------------------- General --------------------

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "eu-west-2"
}

variable "project_name" {
  description = "Name prefix for all resources"
  type        = string
  default     = "kali-linux"
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

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH into the Kali instance (set to your IP)"
  type        = string
  default     = "0.0.0.0/0"
}

# -------------------- EC2 Instance --------------------

variable "kali_ami_id" {
  description = "AMI ID for the Kali Linux image"
  type        = string
#   default     = "ami-0169343dd7b12ae72" # AMD 64-bit AMI
  default     = "ami-0eb6a9667dc410cb9" # ARM 64-bit AMI

}

variable "instance_type" {
  description = "EC2 instance type for the Kali machine"
  type        = string
  default     = "t4g.medium" # ARM/Graviton - use t3.medium for x86_64
}

variable "root_volume_size" {
  description = "Size (GB) of the root EBS volume"
  type        = number
  default     = 30
}

variable "key_pair_name" {
  description = "Name for the generated SSH key pair"
  type        = string
  default     = "kali-linux-key"
}
