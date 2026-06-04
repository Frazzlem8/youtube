# ------- AWS CodePipeline GitHub CI CD - Outputs -------

output "pipeline_name" {
  description = "Name of the CodePipeline pipeline"
  value       = aws_codepipeline.main.name
}

output "artifact_bucket_name" {
  description = "S3 bucket used for CodePipeline artifacts"
  value       = aws_s3_bucket.artifacts.bucket
}

output "website_bucket_name" {
  description = "S3 bucket used for the static website deployment"
  value       = aws_s3_bucket.website.bucket
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.website.domain_name
}

output "website_url" {
  description = "CloudFront URL for the deployed website"
  value       = "https://${aws_cloudfront_distribution.website.domain_name}"
}

output "github_repository" {
  description = "GitHub repository watched by the pipeline"
  value       = local.full_repo_id
}

output "github_branch" {
  description = "GitHub branch watched by the pipeline"
  value       = var.github_branch
}
