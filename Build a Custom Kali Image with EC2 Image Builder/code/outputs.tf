# -------------------------------------------------------
# Build a Custom Kali Image with EC2 Image Builder - Outputs
# -------------------------------------------------------

output "pipeline_arn" {
  description = "ARN of the Image Builder pipeline"
  value       = aws_imagebuilder_image_pipeline.kali.arn
}

output "pipeline_name" {
  description = "Name of the Image Builder pipeline"
  value       = aws_imagebuilder_image_pipeline.kali.name
}

output "recipe_arn" {
  description = "ARN of the image recipe"
  value       = aws_imagebuilder_image_recipe.kali.arn
}

output "component_arn" {
  description = "ARN of the custom Kali setup component"
  value       = aws_imagebuilder_component.kali_setup.arn
}

output "base_ami_id" {
  description = "Base Kali Linux AMI ID used in the recipe"
  value       = data.aws_ami.kali_base.id
}

output "base_ami_name" {
  description = "Name of the base Kali Linux AMI"
  value       = data.aws_ami.kali_base.name
}

output "start_pipeline_command" {
  description = "AWS CLI command to manually trigger a pipeline execution"
  value       = "aws imagebuilder start-image-pipeline-execution --image-pipeline-arn ${aws_imagebuilder_image_pipeline.kali.arn} --region ${var.aws_region}"
}
