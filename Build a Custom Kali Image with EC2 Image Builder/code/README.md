# Build a Custom Kali Image with EC2 Image Builder

Terraform configuration to build a custom Kali Linux AMI using AWS EC2 Image Builder — with baked-in pentesting tools, SSH hardening, and a repeatable pipeline you can run on demand or on a schedule.

## Architecture

```
┌───────────────────────────────────────────────────────────────┐
│  AWS Region (eu-west-2)                                       │
│                                                               │
│  ┌───────────────────────────────────────────────────────┐    │
│  │  EC2 Image Builder                                    │    │
│  │                                                       │    │
│  │  ┌────────────┐    ┌─────────────┐    ┌────────────┐  │    │
│  │  │  Pipeline  │───▶│   Recipe    │─-─▶│ Component  │  │    │
│  │  │ (scheduled │    │ (base AMI + │    │ (tools,    │  │    │
│  │  │  or manual)│    │  components)│    │  hardening)│  │    │
│  │  └────────────┘    └─────────────┘    └────────────┘  │    │
│  │        │                                              │    │
│  │        ▼                                              │    │
│  │  ┌────────────────────────────────────────────────┐   │    │
│  │  │  VPC  10.0.0.0/16                              │   │    │
│  │  │                                                │   │    │
│  │  │  ┌──────────────────────────────────────────┐  │   │    │
│  │  │  │  Public Subnet  10.0.1.0/24              │  │   │    │
│  │  │  │                                          │  │   │    │
│  │  │  │   ┌──────────────────────────────────┐   │  │   │    │
│  │  │  │   │  Build Instance (t3.medium)      │   │  │   │    │
│  │  │  │   │  - Launches from base Kali AMI   │   │  │   │    │
│  │  │  │   │  - Runs component steps          │   │  │   │    │
│  │  │  │   │  - Creates snapshot → new AMI    │   │  │   │    │
│  │  │  │   │  - Terminates automatically      │   │  │   │    │
│  │  │  │   └──────────────────────────────────┘   │  │   │    │
│  │  │  │                                          │  │   │    │
│  │  │  └──────────────────────────────────────────┘  │   │    │
│  │  │                      │                         │   │    │
│  │  │             ┌────────┴────────┐                │   │    │
│  │  │             │ Internet Gateway│                │   │    │
│  │  │             └─────────────────┘                │   │    │
│  │  └────────────────────────────────────────────────┘   │    │
│  │        │                                              │    │
│  │        ▼                                              │    │
│  │  ┌──────────────────┐                                 │    │
│  │  │  Distribution    │                                 │    │
│  │  │  → Custom AMI    │                                 │    │
│  │  │    (eu-west-2)   │                                 │    │
│  │  └──────────────────┘                                 │    │
│  └───────────────────────────────────────────────────────┘    │
└───────────────────────────────────────────────────────────────┘
```

## Prerequisites

| Requirement | Version |
|---|---|
| [Terraform](https://developer.hashicorp.com/terraform/downloads) | >= 1.5.0 |
| [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) | v2 |
| AWS account with appropriate permissions | — |
| Accept the [Kali Linux AMI](https://aws.amazon.com/marketplace/pp/prodview-fznsw3f7mq7to) on the AWS Marketplace | — |

> **Note:** You must subscribe to the Kali Linux AMI in the AWS Marketplace before Image Builder can use it as a base image.

## Quick Start

### 1. Clone the repository

```bash
git clone <repo-url>
cd "Build a Custom Kali Image with EC2 Image Builder"
```

### 2. Configure your variables

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` if you want to change defaults (region, instance type, etc.).

### 3. Deploy the pipeline

```bash
# Initialise Terraform
terraform init

# Preview the changes
terraform plan

# Deploy the infrastructure
terraform apply
```

### 4. Run the pipeline

The pipeline is set to manual by default. Trigger a build with:

```bash
aws imagebuilder start-image-pipeline-execution \
  --image-pipeline-arn $(terraform output -raw pipeline_arn) \
  --region eu-west-2
```

### 5. Monitor the build

```bash
# Check pipeline executions
aws imagebuilder list-image-pipeline-images \
  --image-pipeline-arn $(terraform output -raw pipeline_arn) \
  --region eu-west-2
```

> **Note:** Builds typically take 30–45 minutes. The build instance launches, runs the component, creates a snapshot, tests the image, then terminates automatically.

### 6. Use your custom AMI

Once the build completes, find your AMI in the EC2 console under **AMIs** → **Owned by me**, or use:

```bash
aws ec2 describe-images --owners self \
  --filters "Name=name,Values=kali-image-builder-*" \
  --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
  --output text --region eu-west-2
```

### 7. Destroy

When you're finished, tear everything down:

```bash
terraform destroy
```

> **Note:** `terraform destroy` removes the pipeline, recipe, component, and infrastructure — but **not** any AMIs that were already built. Deregister those manually if needed.

## File Structure

```
.
├── main.tf                    # VPC, IAM, Image Builder pipeline & resources
├── variables.tf               # Input variables
├── outputs.tf                 # Output values (ARNs, CLI commands)
├── providers.tf               # Terraform & provider configuration
├── terraform.tfvars.example   # Example variable values
├── components/
│   └── kali-setup.yml         # Image Builder component (tools & hardening)
├── .gitignore
└── README.md
```

## Variables

| Name | Description | Default |
|---|---|---|
| `aws_region` | AWS region to deploy into | `eu-west-2` |
| `project_name` | Name prefix for all resources | `kali-image-builder` |
| `instance_type` | Instance type for build instances | `t3.medium` |
| `root_volume_size` | Root volume size in GB | `40` |
| `image_recipe_version` | Semantic version for the recipe | `1.0.0` |
| `component_version` | Semantic version for the component | `1.0.0` |
| `distribution_regions` | Regions to distribute the AMI to | `["eu-west-2"]` |
| `pipeline_schedule` | Cron schedule (empty = manual only) | `""` |

## What the Component Installs

The [Image Builder component](components/kali-setup.yml) runs during the AMI build and:

1. Updates all system packages
2. Installs core pentesting tools (`nmap`, `gobuster`, `sqlmap`, `ffuf`, `hydra`, `hashcat`, `seclists`, `crackmapexec`, etc.)
3. Installs useful utilities (`tmux`, `jq`, `htop`, `vim`, `git`, etc.)
4. Installs AWS CLI v2
5. Hardens SSH (disables root login, password auth, X11 forwarding)
6. Sets timezone to UTC
7. Configures a login banner
8. Cleans up package caches to reduce AMI size
9. Validates all tools are installed correctly
10. Runs version checks as a smoke test

## Security Considerations

- **No inbound ports** open on the build instance — only outbound for package downloads
- **Build instances terminate automatically** after the build completes (or fails)
- **SSH is hardened** in the resulting AMI — password auth and root login disabled
- **EBS volumes are encrypted** in the image recipe
- **IAM role** follows least privilege — only SSM and Image Builder permissions
- Only use the resulting AMI for **authorised penetration testing**

## Estimated Cost

- **Build instance:** `t3.medium` runs for ~30–45 minutes per build (~$0.02 per build)
- **AMI storage:** EBS snapshot storage (~$0.05/GB/month for 40 GB = ~$2/month)
- **Pipeline infrastructure:** No ongoing cost when not building (VPC, IAM = free)
- Remember to deregister unused AMIs and delete their snapshots to avoid storage charges

## Troubleshooting

| Issue | Solution |
|---|---|
| AMI not found | Ensure you've subscribed to the [Kali Linux AMI](https://aws.amazon.com/marketplace/pp/prodview-fznsw3f7mq7to) in the Marketplace |
| Build fails at component | Check Image Builder logs in CloudWatch: `/aws/imagebuilder/kali-image-builder` |
| Build timeout | Default is 60 min — increase `image_tests_configuration.timeout_minutes` if needed |
| Permission denied | Verify the IAM role has `EC2InstanceProfileForImageBuilder` and `AmazonSSMManagedInstanceCore` policies |
| Recipe version conflict | Bump `image_recipe_version` and `component_version` — Image Builder won't overwrite existing versions |
| AMI not appearing after build | Check the distribution config region matches where you're looking. Builds take 30–45 min |
