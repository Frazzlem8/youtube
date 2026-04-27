# Deploy a Kali Linux Machine in AWS

Terraform configuration to deploy a fully configured Kali Linux EC2 instance on AWS — complete with a dedicated VPC, security group, SSH key pair, and an initial setup script.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│  AWS Region (eu-west-2)                                 │
│                                                         │
│  ┌───────────────────────────────────────────────────┐  │
│  │  VPC  10.0.0.0/16                                 │  │
│  │                                                   │  │
│  │  ┌─────────────────────────────────────────────┐  │  │
│  │  │  Public Subnet  10.0.1.0/24                 │  │  │
│  │  │                                             │  │  │
│  │  │   ┌──────────────────────────────┐          │  │  │
│  │  │   │  Kali Linux EC2 (t3.medium)  │          │  │  │
│  │  │   │  - 30 GB gp3 (encrypted)     │          │  │  │
│  │  │   │  - IMDSv2 enforced           │          │  │  │
│  │  │   │  - SSH (port 22)             │          │  │  │
│  │  │   └──────────────────────────────┘          │  │  │
│  │  │                                             │  │  │
│  │  └─────────────────────────────────────────────┘  │  │
│  │                       │                           │  │
│  │              ┌────────┴────────┐                  │  │
│  │              │ Internet Gateway│                  │  │
│  │              └─────────────────┘                  │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

## Prerequisites

| Requirement | Version |
|---|---|
| [Terraform](https://developer.hashicorp.com/terraform/downloads) | >= 1.5.0 |
| [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) | v2 |
| AWS account with appropriate permissions | — |
| Accept the [Kali Linux AMI](https://aws.amazon.com/marketplace/pp/prodview-fznsw3f7mq7to) on the AWS Marketplace | — |

> **Note:** You must subscribe to the Kali Linux AMI in the AWS Marketplace before Terraform can launch an instance from it.

## Quick Start

### 1. Clone the repository

```bash
git clone <repo-url>
cd "Deploy a Kali Linux machine in AWS"
```

### 2. Configure your variables

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and set your public IP:

```bash
# Find your public IP
curl -s https://checkip.amazonaws.com

# Then update terraform.tfvars
allowed_ssh_cidr = "YOUR_IP/32"
```

### 3. Deploy

```bash
# Initialise Terraform
terraform init

# Preview the changes
terraform plan

# Deploy the infrastructure
terraform apply
```

### 4. Connect

Once the apply completes, Terraform outputs the SSH command:

```bash
# The SSH command is displayed in the outputs, e.g.:
ssh -i kali-linux-key.pem kali@<PUBLIC_IP>
```

> **Default user:** `kali`

### 5. Destroy

When you're finished, tear everything down:

```bash
terraform destroy
```

## File Structure

```
.
├── main.tf                    # VPC, subnet, security group, EC2 instance
├── variables.tf               # Input variables
├── outputs.tf                 # Output values (IP, SSH command, etc.)
├── providers.tf               # Terraform & provider configuration
├── terraform.tfvars.example   # Example variable values
├── scripts/
│   └── setup.sh               # User data script (runs on first boot)
├── .gitignore
└── README.md
```

## Variables

| Name | Description | Default |
|---|---|---|
| `aws_region` | AWS region to deploy into | `eu-west-2` |
| `project_name` | Name prefix for all resources | `kali-linux` |
| `instance_type` | EC2 instance type | `t3.medium` |
| `root_volume_size` | Root volume size in GB | `30` |
| `key_pair_name` | Name for the SSH key pair | `kali-linux-key` |
| `allowed_ssh_cidr` | CIDR allowed to SSH in (**required**) | — |

## What the Setup Script Does

The [user data script](scripts/setup.sh) runs automatically on first boot and:

1. Updates all system packages
2. Installs useful utilities (`tmux`, `jq`, `htop`, `tree`, etc.)
3. Installs AWS CLI v2
4. Hardens SSH (disables root login & password authentication)
5. Sets the timezone to UTC
6. Configures a login banner

## Security Considerations

- **SSH is locked down** to the CIDR you specify — never use `0.0.0.0/0`
- **IMDSv2** is enforced on the instance (prevents SSRF-based credential theft)
- **Root EBS volume is encrypted** at rest
- **Password authentication is disabled** — key-based auth only
- Only use Kali Linux for **authorised penetration testing** and security assessments

## Estimated Cost

Running a `t3.medium` instance in `eu-west-2` costs approximately **~$0.04/hour** (~$30/month if left running 24/7). Remember to `terraform destroy` when you're done to avoid charges.

## Troubleshooting

| Issue | Solution |
|---|---|
| AMI not found | Ensure you've subscribed to the [Kali Linux AMI](https://aws.amazon.com/marketplace/pp/prodview-fznsw3f7mq7to) in the Marketplace |
| SSH timeout | Verify `allowed_ssh_cidr` matches your current public IP |
| Permission denied (key) | Check the key file permissions: `chmod 400 kali-linux-key.pem` |
| User data didn't run | Check `/var/log/kali-setup.log` on the instance |
