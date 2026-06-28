# ------- AWS Lambda MicroVMs - Main -------

# -------------------- Data Sources --------------------

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

# -------------------- Locals --------------------

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = {
    Name        = var.project_name
    Environment = var.environment
    Owner       = var.owner
  }
}

# -------------------- Artifact Bucket --------------------

resource "random_id" "artifact_bucket" {
  byte_length = 4
}

resource "aws_s3_bucket" "artifacts" {
  bucket = "${local.name_prefix}-artifacts-${random_id.artifact_bucket.hex}"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-artifacts"
  })
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}

# -------------------- MicroVM Artifact --------------------

data "archive_file" "microvm_artifact" {
  type        = "zip"
  source_dir  = "${path.module}/${var.app_source_dir}"
  output_path = "${path.module}/build/${var.image_name}.zip"
}

resource "aws_s3_object" "microvm_artifact" {
  bucket      = aws_s3_bucket.artifacts.id
  key         = var.artifact_key
  source      = data.archive_file.microvm_artifact.output_path
  source_hash = data.archive_file.microvm_artifact.output_base64sha256
}

# -------------------- Build Logs --------------------

resource "aws_cloudwatch_log_group" "microvm" {
  name              = "/aws/lambda-microvms/${var.image_name}"
  retention_in_days = 14

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-microvm-build-logs"
  })
}

# -------------------- Build Role --------------------

data "aws_iam_policy_document" "microvm_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
      "sts:TagSession",
    ]
  }
}

resource "aws_iam_role" "microvm_build" {
  name               = "${local.name_prefix}-${var.image_name}-build"
  assume_role_policy = data.aws_iam_policy_document.microvm_assume_role.json

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-microvm-build-role"
  })
}

data "aws_iam_policy_document" "microvm_build" {
  statement {
    sid    = "ReadMicrovmArtifact"
    effect = "Allow"

    actions = ["s3:GetObject"]

    resources = [aws_s3_object.microvm_artifact.arn]
  }

  statement {
    sid    = "WriteBuildLogs"
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      aws_cloudwatch_log_group.microvm.arn,
      "${aws_cloudwatch_log_group.microvm.arn}:*",
    ]
  }

  statement {
    sid    = "CreateBuildLogGroupIfMissing"
    effect = "Allow"

    actions   = ["logs:CreateLogGroup"]
    resources = ["arn:${data.aws_partition.current.partition}:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda-microvms/*"]
  }
}

resource "aws_iam_role_policy" "microvm_build" {
  name   = "${local.name_prefix}-${var.image_name}-build"
  role   = aws_iam_role.microvm_build.id
  policy = data.aws_iam_policy_document.microvm_build.json
}

# -------------------- Lambda MicroVM Image --------------------

resource "aws_cloudformation_stack" "microvm_image" {
  name = "${local.name_prefix}-${var.image_name}-image"

  template_body = jsonencode({
    AWSTemplateFormatVersion = "2010-09-09"
    Description              = "Lambda MicroVM image managed by Terraform through CloudFormation."
    Resources = {
      MicrovmImage = {
        Type = "AWS::Lambda::MicrovmImage"
        Properties = {
          Name                     = var.image_name
          BaseImageArn             = "arn:${data.aws_partition.current.partition}:lambda:${var.aws_region}:aws:microvm-image:${var.base_image_name}"
          BaseImageVersion         = var.base_image_version
          BuildRoleArn             = aws_iam_role.microvm_build.arn
          CodeArtifact             = { Uri = "s3://${aws_s3_bucket.artifacts.id}/${aws_s3_object.microvm_artifact.key}" }
          CpuConfigurations        = [{ Architecture = "ARM_64" }]
          AdditionalOsCapabilities = ["ALL"]
          Description              = "Demo application packaged as an AWS Lambda MicroVM image"
          EgressNetworkConnectors  = []
          EnvironmentVariables     = []
          Hooks                    = {}
          Logging = {
            CloudWatch = {
              LogGroup = aws_cloudwatch_log_group.microvm.name
            }
          }
          Resources = [{
            MinimumMemoryInMiB = var.minimum_memory_mib
          }]
          Tags = [for key, value in merge(local.common_tags, {
            Project   = var.project_name
            ManagedBy = "Terraform"
            }) : {
            Key   = key
            Value = value
          }]
        }
      }
    }
    Outputs = {
      ImageArn = {
        Value = { "Fn::GetAtt" = ["MicrovmImage", "ImageArn"] }
      }
      ImageState = {
        Value = { "Fn::GetAtt" = ["MicrovmImage", "State"] }
      }
      LatestActiveImageVersion = {
        Value = { "Fn::GetAtt" = ["MicrovmImage", "LatestActiveImageVersion"] }
      }
    }
  })

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-microvm-image-stack"
  })

  depends_on = [
    aws_iam_role_policy.microvm_build,
    aws_s3_object.microvm_artifact,
    aws_cloudwatch_log_group.microvm,
  ]
}
