# ------- AWS CodePipeline GitHub CI CD - Variables -------

# -------------------- General --------------------

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "eu-west-2"
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "codepipeline-github-demo"
}

# -------------------- GitHub Source --------------------

variable "connection_arn" {
  description = "AWS CodeConnections connection ARN for GitHub"
  type        = string
}

variable "github_owner" {
  description = "GitHub organization or username that owns the repository"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "github_branch" {
  description = "Git branch that should trigger the pipeline"
  type        = string
  default     = "main"
}

# -------------------- Build --------------------

variable "build_compute_type" {
  description = "CodeBuild compute type"
  type        = string
  default     = "BUILD_GENERAL1_SMALL"
}

variable "build_image" {
  description = "CodeBuild managed image"
  type        = string
  default     = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
}
