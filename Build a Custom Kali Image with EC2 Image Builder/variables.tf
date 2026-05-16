# -------------------------------------------------------
# Build a Custom Kali Image with EC2 Image Builder - Variables
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
  default     = "kali-image-builder"
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

# -------------------- Image Builder --------------------

variable "base_ami_name" {
  description = "Name filter to find the base Kali Linux AMI"
  type        = string
  default     = "kali-last-snapshot-amd64-2025*"
}

variable "base_ami_owners" {
  description = "AWS account IDs that own the base Kali AMI (OffSec)"
  type        = list(string)
  default     = ["679593333241"]
}

variable "instance_type" {
  description = "Instance type used during image builds"
  type        = string
  default     = "t3.medium" # x86_64 required for Kali Marketplace AMI
}

variable "root_volume_size" {
  description = "Size (GB) of the root EBS volume for the built image"
  type        = number
  default     = 40
}

variable "image_recipe_version" {
  description = "Semantic version for the image recipe (leave null to auto-generate)"
  type        = string
  default     = null
}

variable "component_version" {
  description = "Semantic version for the custom component (leave null to auto-generate)"
  type        = string
  default     = null
}

variable "distribution_regions" {
  description = "List of regions to distribute the built AMI to"
  type        = list(string)
  default     = ["eu-west-2"]
}

# -------------------- Pipeline Schedule --------------------

variable "pipeline_schedule" {
  description = "Cron expression for pipeline schedule (empty string = manual only)"
  type        = string
  default     = ""
}
