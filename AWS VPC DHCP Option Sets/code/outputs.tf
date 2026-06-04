# ------- AWS VPC DHCP Option Sets - Outputs -------

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "dhcp_options_id" {
  description = "ID of the custom DHCP option set"
  value       = aws_vpc_dhcp_options.custom.id
}

output "private_hosted_zone_id" {
  description = "ID of the Route 53 private hosted zone"
  value       = aws_route53_zone.private.zone_id
}

output "kali_instance_id" {
  description = "ID of the kali EC2 instance"
  value       = aws_instance.kali.id
}

output "kali_public_ip" {
  description = "Public IP of the kali instance"
  value       = aws_instance.kali.public_ip
}

output "kali_private_ip" {
  description = "Private IP of the kali instance"
  value       = aws_instance.kali.private_ip
}

output "kali_dns_name" {
  description = "Custom DNS name for the kali instance"
  value       = "kali.${var.custom_domain_name}"
}

output "target_instance_id" {
  description = "ID of the target EC2 instance"
  value       = aws_instance.target.id
}

output "target_public_ip" {
  description = "Public IP of the target instance"
  value       = aws_instance.target.public_ip
}

output "target_private_ip" {
  description = "Private IP of the target instance"
  value       = aws_instance.target.private_ip
}

output "target_dns_name" {
  description = "Custom DNS name for the target instance"
  value       = "target.${var.custom_domain_name}"
}

output "custom_domain_name" {
  description = "Custom domain name configured in the DHCP option set"
  value       = var.custom_domain_name
}

output "ssh_command_kali" {
  description = "SSH command to connect to the kali instance"
  value       = "ssh -i ${var.project_name}-key.pem kali@${aws_instance.kali.public_ip}"
}

output "ssh_command_target" {
  description = "SSH command to connect to the target instance"
  value       = "ssh -i ${var.project_name}-key.pem ec2-user@${aws_instance.target.public_ip}"
}
