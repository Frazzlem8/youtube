# ------- AWS VPC Lattice - Variables -------

# -------------------- General --------------------

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "eu-west-2"
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "lattice-demo"
}

# -------------------- Networking --------------------

variable "orders_vpc_cidr" {
  description = "CIDR block for the orders/client VPC"
  type        = string
  default     = "10.10.0.0/16"
}

variable "orders_public_subnet_cidr" {
  description = "CIDR block for the orders/client public subnet"
  type        = string
  default     = "10.10.1.0/24"
}

variable "payments_vpc_cidr" {
  description = "CIDR block for the payments/service VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "payments_public_subnet_cidr" {
  description = "CIDR block for the payments/service public subnet"
  type        = string
  default     = "10.20.1.0/24"
}

# -------------------- EC2 --------------------

variable "instance_type" {
  description = "EC2 instance type for the demo instances"
  type        = string
  default     = "t3.micro"
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH into the client instance"
  type        = string
}
