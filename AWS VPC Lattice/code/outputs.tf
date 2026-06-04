# ------- AWS VPC Lattice - Outputs -------

output "orders_vpc_id" {
  description = "ID of the orders/client VPC"
  value       = aws_vpc.orders.id
}

output "payments_vpc_id" {
  description = "ID of the payments/service VPC"
  value       = aws_vpc.payments.id
}

output "service_network_id" {
  description = "ID of the VPC Lattice service network"
  value       = aws_vpclattice_service_network.main.id
}

output "payments_service_id" {
  description = "ID of the VPC Lattice payments service"
  value       = aws_vpclattice_service.payments.id
}

output "payments_service_domain_name" {
  description = "Generated domain name for the VPC Lattice payments service"
  value       = aws_vpclattice_service.payments.dns_entry[0].domain_name
}

output "orders_client_public_ip" {
  description = "Public IP of the orders client instance"
  value       = aws_instance.orders_client.public_ip
}

output "orders_client_private_ip" {
  description = "Private IP of the orders client instance"
  value       = aws_instance.orders_client.private_ip
}

output "payments_instance_private_ip" {
  description = "Private IP of the payments service instance"
  value       = aws_instance.payments_service.private_ip
}

output "ssh_command_orders_client" {
  description = "SSH command to connect to the orders client instance"
  value       = "ssh -i ${var.project_name}-key.pem ec2-user@${aws_instance.orders_client.public_ip}"
}

output "curl_payments_service" {
  description = "Command to call the payments service through VPC Lattice from the orders client"
  value       = "curl http://${aws_vpclattice_service.payments.dns_entry[0].domain_name}"
}
