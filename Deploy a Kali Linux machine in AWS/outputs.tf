# -------------------------------------------------------
# Deploy a Kali Linux Machine in AWS - Outputs
# -------------------------------------------------------

output "kali_instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.kali.id
}

output "kali_public_ip" {
  description = "Public IP address of the Kali instance"
  value       = aws_instance.kali.public_ip
}

output "kali_public_dns" {
  description = "Public DNS name of the Kali instance"
  value       = aws_instance.kali.public_dns
}

output "kali_ami_id" {
  description = "AMI ID used for the Kali instance"
  value       = var.kali_ami_id
}

output "ssh_private_key_path" {
  description = "Path to the generated SSH private key"
  value       = local_file.private_key.filename
}

output "ssh_connection_command" {
  description = "SSH command to connect to the Kali instance"
  value       = "ssh -i ${local_file.private_key.filename} kali@${aws_instance.kali.public_ip}"
}
