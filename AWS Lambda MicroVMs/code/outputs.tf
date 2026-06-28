# ------- AWS Lambda MicroVMs - Outputs -------

output "aws_region" {
  description = "AWS Region used by this deployment."
  value       = var.aws_region
}

output "artifact_bucket_name" {
  description = "S3 bucket storing the MicroVM application zip."
  value       = aws_s3_bucket.artifacts.id
}

output "artifact_s3_uri" {
  description = "S3 URI of the MicroVM application zip."
  value       = "s3://${aws_s3_bucket.artifacts.id}/${aws_s3_object.microvm_artifact.key}"
}

output "build_role_arn" {
  description = "IAM role assumed by Lambda while building the MicroVM image."
  value       = aws_iam_role.microvm_build.arn
}

output "microvm_image_arn" {
  description = "ARN of the created Lambda MicroVM image."
  value       = lookup(aws_cloudformation_stack.microvm_image.outputs, "ImageArn", null)
}

output "microvm_image_state" {
  description = "Current state returned by the CloudFormation MicroVM image resource."
  value       = lookup(aws_cloudformation_stack.microvm_image.outputs, "ImageState", null)
}

output "latest_active_image_version" {
  description = "Latest active MicroVM image version."
  value       = lookup(aws_cloudformation_stack.microvm_image.outputs, "LatestActiveImageVersion", null)
}

output "run_microvm_command" {
  description = "Command to launch a MicroVM from the created image."
  value       = "./scripts/run-microvm.sh"
}
