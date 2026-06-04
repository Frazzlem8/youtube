# -------------------------------------------------------
# Build a Custom Kali Image with EC2 Image Builder - Provider Config
# -------------------------------------------------------

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "Kali-Image-Builder"
      ManagedBy = "Terraform"
    }
  }
}
