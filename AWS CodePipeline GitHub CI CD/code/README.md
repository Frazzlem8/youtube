# AWS CodePipeline GitHub CI/CD - Terraform

Deploy a simple AWS CI/CD pipeline that pulls source from GitHub using AWS CodeConnections, builds a static app with AWS CodeBuild, deploys it to a private S3 bucket, and serves it through CloudFront.

## Architecture

```
GitHub repo  ->  CodePipeline Source  ->  CodeBuild  ->  private S3 bucket  ->  CloudFront
              AWS CodeConnections       buildspec.yml   deployed artifact       public HTTPS URL
```

## Prerequisites

| Tool | Version |
|------|---------|
| Terraform | >= 1.5.0 |
| AWS CLI | v2 |
| AWS Account | With CodePipeline, CodeBuild, S3, IAM, and CodeConnections permissions |
| GitHub Repository | Contains the YouTube workspace root with `buildspec.yml` at repo root |

## Important: GitHub Connection Setup

The GitHub authorization step cannot be completed by Terraform alone. Create the connection in the AWS Console first:

1. Go to **Developer Tools** -> **Settings** -> **Connections**.
2. Create a connection to **GitHub**.
3. Install or authorize the AWS Connector for GitHub app.
4. Wait until the connection status is **Available**.
5. Copy the connection ARN into `terraform.tfvars`.

AWS now calls this service **CodeConnections**. Some CodePipeline action names and IAM permissions still reference `CodeStarSourceConnection` or `codestar-connections`.

## Quick Start

```bash
# 1. Use the YouTube workspace as the GitHub repo root
# buildspec.yml must be at the root of git@github.com:Frazzlem8/youtube.git

# 2. Configure variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your connection ARN, GitHub owner, repo, and branch

# 3. Deploy
terraform init
terraform plan
terraform apply

# 4. Watch the first pipeline run
# AWS Console -> CodePipeline -> codepipeline-github-demo-pipeline

# 5. Open the website URL from Terraform outputs
terraform output website_url

# 6. Make a Git commit and push it
# The pipeline should trigger automatically

# 7. Destroy when done
terraform destroy
```

## File Structure

```
AWS CodePipeline GitHub CI CD/
├── main.tf                  # S3, CloudFront, IAM, CodeBuild, CodePipeline
├── variables.tf             # Input variables
├── outputs.tf               # Pipeline and website outputs
├── providers.tf             # Provider configuration
├── terraform.tfvars.example # Example variable values
├── demo-app/                # Static website source
├── .gitignore               # Ignore state and local config
└── README.md                # This file
```

## Variables

| Name | Description | Default |
|------|-------------|---------|
| `aws_region` | AWS region to deploy into | `eu-west-2` |
| `project_name` | Project name for resource naming | `codepipeline-github-demo` |
| `connection_arn` | AWS CodeConnections connection ARN | - required |
| `github_owner` | GitHub username or organization | - required |
| `github_repo` | GitHub repository name | - required |
| `github_branch` | Branch watched by the pipeline | `main` |
| `build_compute_type` | CodeBuild compute size | `BUILD_GENERAL1_SMALL` |
| `build_image` | CodeBuild managed image | `aws/codebuild/amazonlinux2-x86_64-standard:5.0` |

## What This Deploys

1. S3 artifact bucket for CodePipeline
2. Private S3 bucket for deployment
3. CodeBuild project using `buildspec.yml`
4. IAM role and policy for CodeBuild
5. IAM role and policy for CodePipeline
6. CodePipeline V2 pipeline with Source, Build, and Deploy stages
7. GitHub source action using AWS CodeConnections
8. CloudFront distribution with Origin Access Control for public HTTPS access

## Demo Flow

1. Explain CI/CD: source, build, deploy.
2. Create or show the GitHub connection in AWS.
3. Deploy the Terraform.
4. Watch the pipeline pull from GitHub.
5. Show CodeBuild logs.
6. Open the CloudFront website URL.
7. Change the HTML, commit, and push.
8. Watch the pipeline trigger automatically and deploy the new version.

## Estimated Cost

| Resource | Cost |
|---|---|
| CodePipeline V2 | Charged by action execution minutes |
| CodeBuild | Charged by build minutes and compute type |
| S3 artifact bucket | Storage and requests |
| S3 website bucket | Storage and requests |
| CloudFront | Data transfer and requests |

Run `terraform destroy` when done to avoid ongoing charges.

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Connection status is pending | Complete the GitHub app authorization in the AWS Console |
| Pipeline cannot use the connection | Check the pipeline role has `codeconnections:UseConnection` and `codestar-connections:UseConnection` |
| Pipeline does not trigger on push | Confirm repo owner, repo name, branch name, and GitHub connection installation access |
| Build fails with missing files | Confirm root `buildspec.yml` points to `AWS CodePipeline GitHub CI CD/code/demo-app/src/` |
| Website shows old content | Wait for the deploy stage to finish, then refresh the CloudFront URL |
| S3 bucket policy is denied | This demo uses CloudFront OAC so the bucket policy is not public; run `terraform apply` with the updated files |
