# ------- AWS Lambda MicroVMs - Variables -------

variable "aws_region" {
  description = "AWS Region where the Lambda MicroVM image and supporting resources are created."
  type        = string
  default     = "eu-west-1"
}

variable "project_name" {
  description = "Project name for resource naming and tagging."
  type        = string
  default     = "lambda-microvm-demo"
}

variable "environment" {
  description = "Environment name for resource tagging."
  type        = string
  default     = "demo"
}

variable "owner" {
  description = "Owner tag value."
  type        = string
  default     = "youtube"
}

variable "image_name" {
  description = "Lambda MicroVM image name. Must be unique in the account and Region."
  type        = string
  default     = "youtube-http-api"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]{1,64}$", var.image_name))
    error_message = "image_name must be 1-64 characters and contain only letters, numbers, hyphens, and underscores."
  }
}

variable "base_image_name" {
  description = "AWS-managed Lambda MicroVM base image name."
  type        = string
  default     = "al2023-1"
}

variable "base_image_version" {
  description = "AWS-managed Lambda MicroVM base image version."
  type        = string
  default     = "0"
}

variable "minimum_memory_mib" {
  description = "Baseline memory for each MicroVM launched from this image."
  type        = number
  default     = 1024

  validation {
    condition     = contains([512, 1024, 2048, 4096, 8192], var.minimum_memory_mib)
    error_message = "minimum_memory_mib must be one of 512, 1024, 2048, 4096, or 8192."
  }
}

variable "app_source_dir" {
  description = "Directory containing the MicroVM Dockerfile and application files."
  type        = string
  default     = "apps/http-api"
}

variable "artifact_key" {
  description = "S3 object key for the zipped MicroVM application artifact."
  type        = string
  default     = "artifacts/microvm-app.zip"
}
