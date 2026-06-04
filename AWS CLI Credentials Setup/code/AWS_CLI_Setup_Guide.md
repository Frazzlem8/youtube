# AWS CLI Credentials Setup Guide

A quick guide to configuring AWS CLI credentials in your terminal.

## Prerequisites

First, ensure AWS CLI is installed:

```bash
# Check if AWS CLI is installed
aws --version

# Install on macOS (if needed)
brew install awscli

# Or using pip
pip install awscli
```

## Method 1: Using `aws configure` (Recommended)

The simplest way to set up credentials:

```bash
aws configure
```

You'll be prompted to enter:
- **AWS Access Key ID**: Your access key (e.g., `AKIAIOSFODNN7EXAMPLE`)
- **AWS Secret Access Key**: Your secret key (e.g., `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`)
- **Default region**: Your preferred region (e.g., `us-east-1`)
- **Default output format**: `json`, `yaml`, `text`, or `table` (json recommended)

### Example:
```
$ aws configure
AWS Access Key ID [None]: AKIAIOSFODNN7EXAMPLE
AWS Secret Access Key [None]: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
Default region name [None]: us-east-1
Default output format [None]: json
```

This creates two files:
- `~/.aws/credentials` - Stores your access keys
- `~/.aws/config` - Stores configuration settings

## Method 2: Using Environment Variables

Set credentials temporarily for the current terminal session:

```bash
export AWS_ACCESS_KEY_ID="AKIAIOSFODNN7EXAMPLE"
export AWS_SECRET_ACCESS_KEY="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
export AWS_DEFAULT_REGION="us-east-1"
```

To make these permanent, add them to your shell profile:

```bash
# For zsh (macOS default)
echo 'export AWS_ACCESS_KEY_ID="your-key-id"' >> ~/.zshrc
echo 'export AWS_SECRET_ACCESS_KEY="your-secret-key"' >> ~/.zshrc
echo 'export AWS_DEFAULT_REGION="us-east-1"' >> ~/.zshrc
source ~/.zshrc

# For bash
echo 'export AWS_ACCESS_KEY_ID="your-key-id"' >> ~/.bash_profile
echo 'export AWS_SECRET_ACCESS_KEY="your-secret-key"' >> ~/.bash_profile
echo 'export AWS_DEFAULT_REGION="us-east-1"' >> ~/.bash_profile
source ~/.bash_profile
```

## Method 3: Manually Edit Credentials File

Create or edit `~/.aws/credentials`:

```bash
mkdir -p ~/.aws
nano ~/.aws/credentials
```

Add your credentials:

```ini
[default]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

Create or edit `~/.aws/config`:

```bash
nano ~/.aws/config
```

Add configuration:

```ini
[default]
region = us-east-1
output = json
```

## Using Multiple Profiles

You can configure multiple AWS profiles for different accounts:

```bash
aws configure --profile personal
aws configure --profile work
```

This creates separate credential sets in `~/.aws/credentials`:

```ini
[default]
aws_access_key_id = KEY1
aws_secret_access_key = SECRET1

[personal]
aws_access_key_id = KEY2
aws_secret_access_key = SECRET2

[work]
aws_access_key_id = KEY3
aws_secret_access_key = SECRET3
```

Use a specific profile:

```bash
# Using --profile flag
aws s3 ls --profile work

# Using environment variable
export AWS_PROFILE=work
aws s3 ls
```

## Verify Your Configuration

Test your credentials are working:

```bash
# Check current identity
aws sts get-caller-identity

# List S3 buckets (if you have permissions)
aws s3 ls

# Check current configuration
aws configure list
```

Expected output from `get-caller-identity`:

```json
{
    "UserId": "AIDAI...",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/your-username"
}
```

## Getting Your AWS Credentials

If you don't have credentials yet:

1. **Sign in to AWS Console**: https://console.aws.amazon.com
2. **Navigate to IAM**: Services → IAM → Users
3. **Select your user** (or create a new one)
4. **Security credentials tab**
5. **Create access key** → Select "Command Line Interface (CLI)"
6. **Download or copy** your credentials immediately (you can't retrieve the secret key later)

## Security Best Practices

⚠️ **Important Security Notes:**

- **Never commit credentials to Git** - Add `~/.aws/` to `.gitignore`
- **Use IAM roles** when running on EC2 instances instead of hardcoded credentials
- **Rotate credentials** regularly
- **Use least privilege** - Only grant necessary permissions
- **Enable MFA** for your AWS account
- **Use AWS Secrets Manager** or **Parameter Store** for application credentials

## For Terraform Users

Terraform automatically uses AWS CLI credentials. Just ensure credentials are configured, then run:

```bash
terraform init
terraform plan
terraform apply
```

Terraform checks credentials in this order:
1. Environment variables (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`)
2. Shared credentials file (`~/.aws/credentials`)
3. IAM role (when running on EC2)

## Troubleshooting

**"Unable to locate credentials"**
- Verify credentials are set: `aws configure list`
- Check file exists: `cat ~/.aws/credentials`

**"The security token included in the request is invalid"**
- Your access keys may be incorrect or deactivated
- Regenerate keys in IAM console

**"Access Denied"**
- Your user lacks necessary IAM permissions
- Contact your AWS administrator

## Quick Reference Commands

```bash
# Configure default profile
aws configure

# Configure named profile
aws configure --profile myprofile

# List configuration
aws configure list

# Get specific config value
aws configure get region
aws configure get aws_access_key_id

# Set specific config value
aws configure set region us-west-2
aws configure set output yaml

# Verify identity
aws sts get-caller-identity

# Use specific profile
export AWS_PROFILE=myprofile
```

---

**Happy cloud computing! 🚀**
