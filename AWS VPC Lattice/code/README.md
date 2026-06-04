# AWS VPC Lattice - Terraform

Deploy a simple AWS VPC Lattice service network that connects an `orders` client in one VPC to a `payments` HTTP service in another VPC without VPC peering or Transit Gateway.

## Architecture

```
Orders VPC                         VPC Lattice                         Payments VPC
----------                         -----------                         ------------
orders-client EC2  --->  service network + payments service  --->  payments EC2 target
10.10.0.0/16                                                           10.20.0.0/16
```

## Prerequisites

| Tool | Version |
|------|---------|
| Terraform | >= 1.5.0 |
| AWS CLI | v2 |
| AWS Account | With VPC, EC2, IAM, and VPC Lattice permissions |

## Quick Start

```bash
# 1. Clone the repo
git clone <REPO_URL> && cd "AWS VPC Lattice"

# 2. Configure variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars - set allowed_ssh_cidr to your IP

# 3. Deploy
terraform init
terraform plan
terraform apply

# 4. Connect to the orders client
ssh -i lattice-demo-key.pem ec2-user@<ORDERS_CLIENT_PUBLIC_IP>

# 5. Call the payments service through VPC Lattice
curl http://<PAYMENTS_SERVICE_DOMAIN_NAME>

# 6. Destroy when done
terraform destroy
```

## File Structure

```
AWS VPC Lattice/
├── main.tf                  # VPCs, EC2, security groups, VPC Lattice resources
├── variables.tf             # Input variables
├── outputs.tf               # Useful outputs and demo commands
├── providers.tf             # AWS provider configuration
├── terraform.tfvars.example # Example variable values
├── .gitignore               # Ignore state, keys, lock files
└── README.md                # This file
```

## Variables

| Name | Description | Default |
|------|-------------|---------|
| `aws_region` | AWS region to deploy into | `eu-west-2` |
| `project_name` | Project name for resource naming | `lattice-demo` |
| `orders_vpc_cidr` | CIDR block for the orders/client VPC | `10.10.0.0/16` |
| `orders_public_subnet_cidr` | CIDR block for the orders/client subnet | `10.10.1.0/24` |
| `payments_vpc_cidr` | CIDR block for the payments/service VPC | `10.20.0.0/16` |
| `payments_public_subnet_cidr` | CIDR block for the payments/service subnet | `10.20.1.0/24` |
| `instance_type` | EC2 instance type for both demo instances | `t3.micro` |
| `allowed_ssh_cidr` | CIDR allowed to SSH into the client instance | - required |

## What This Deploys

1. Two separate VPCs: `orders` and `payments`
2. One public subnet, internet gateway, and route table in each VPC
3. One EC2 client instance in the orders VPC
4. One EC2 HTTP service instance in the payments VPC
5. A VPC Lattice service network
6. VPC associations from both VPCs into the service network
7. A VPC Lattice service named `payments`
8. An instance target group for the payments EC2 instance
9. An HTTP listener that forwards traffic to the payments target group

## Demo Flow

1. Show that the two VPCs have no peering or Transit Gateway.
2. Show the service network and both VPC associations.
3. Show the payments service and target group.
4. SSH to the orders client.
5. Curl the generated VPC Lattice service domain name.
6. Explain that the client reached the private service through VPC Lattice, not direct VPC routing.

## Security Considerations

- SSH access is restricted to your specified CIDR block.
- IMDSv2 is enforced on both EC2 instances.
- EBS root volumes are encrypted.
- The payments instance accepts HTTP only from the AWS-managed VPC Lattice prefix list.
- The starter demo uses `auth_type = "NONE"` so the first demo call works with plain `curl`. For a follow-up segment, switch the service to IAM auth and add a service auth policy.

## Estimated Cost

| Resource | Cost |
|---|---|
| VPC / Subnet / IGW / Route Table | Free |
| EC2 orders client | Charged per instance-hour |
| EC2 payments target | Charged per instance-hour |
| VPC Lattice service | Charged while provisioned |
| VPC Lattice requests / data | Charged by usage |

Run `terraform destroy` when done to avoid ongoing charges.

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Cannot SSH to client | Check `allowed_ssh_cidr` matches your current IP |
| `curl` times out | Wait for the payments instance health check to pass |
| Target group unhealthy | Confirm the payments security group allows the VPC Lattice managed prefix list |
| Prefix list lookup fails | Confirm VPC Lattice is available in the selected region |
| Service call returns DNS error | Run the curl command from inside the associated orders VPC |
