# AWS Lambda MicroVMs - Terraform

Build an AWS Lambda MicroVM image from a container-style application package, launch a running MicroVM, and test it through the authenticated HTTPS endpoint.

## Architecture

```
Local machine
    |
    | terraform apply
    v
S3 artifact bucket ---> Lambda MicroVM image build ---> MicroVM image
                              |
                              v
                       CloudWatch Logs

Local machine -- AWS CLI run-microvm --> running MicroVM endpoint
Local machine -- auth token + HTTPS --> app on port 8080
```

## Prerequisites

| Tool | Version |
|------|---------|
| Terraform | >= 1.5.0 |
| AWS CLI | Recent v2 with `lambda-microvms` command |
| Node.js | 20+ for the optional browser proxy |
| AWS Account | With Lambda MicroVM, S3, IAM, CloudFormation, and CloudWatch Logs permissions |

Check the CLI supports MicroVMs:

```bash
aws lambda-microvms help
```

## Quick Start

```bash
# 1. Clone the repo
git clone <REPO_URL> && cd "AWS Lambda MicroVMs/code"

# 2. Configure variables
cp terraform.tfvars.example terraform.tfvars

# 3. Deploy the MicroVM image resources
terraform init
terraform plan
terraform apply

# 4. Confirm the image is ready
aws lambda-microvms get-microvm-image \
  --region "$(terraform output -raw aws_region)" \
  --image-identifier "$(terraform output -raw microvm_image_arn)"

# 5. Launch a MicroVM
REGION="$(terraform output -raw aws_region)"
IMAGE_ARN="$(terraform output -raw microvm_image_arn)"

aws lambda-microvms run-microvm \
  --region "$REGION" \
  --image-identifier "$IMAGE_ARN" \
  --ingress-network-connectors "arn:aws:lambda:${REGION}:aws:network-connector:aws-network-connector:ALL_INGRESS" \
  --egress-network-connectors "arn:aws:lambda:${REGION}:aws:network-connector:aws-network-connector:INTERNET_EGRESS" \
  --idle-policy '{"autoResumeEnabled":true,"maxIdleDurationSeconds":900,"suspendedDurationSeconds":300}' \
  --maximum-duration-in-seconds 14400

# 6. Call it with the returned MicroVM ID
MICROVM_ID="<microvm-id>"
ENDPOINT="<microvm-endpoint>"

TOKEN="$(aws lambda-microvms create-microvm-auth-token \
  --region "$REGION" \
  --microvm-identifier "$MICROVM_ID" \
  --expiration-in-minutes 30 \
  --allowed-ports '[{"port":8080}]' \
  --query authToken \
  --output text)"

curl "https://${ENDPOINT}/" \
  -H "X-aws-proxy-auth: ${TOKEN}" \
  -H "X-aws-proxy-port: 8080"

# 7. Stop the running MicroVM
aws lambda-microvms terminate-microvm \
  --region "$REGION" \
  --microvm-identifier "$MICROVM_ID"

# 8. Destroy when done
terraform destroy
```

## File Structure

```
code/
├── apps/
│   ├── http-api/        # Node.js JSON API demo
│   ├── system-info/     # Python runtime and OS info demo
│   ├── cpu-worker/      # Python CPU work demo
│   └── ai-code-sandbox/ # AI-generated code execution sandbox use case
├── scripts/
│   ├── browser-proxy.js
│   ├── call-microvm.sh
│   ├── run-microvm.sh
│   └── terminate-microvm.sh
├── main.tf
├── variables.tf
├── outputs.tf
├── providers.tf
├── terraform.tfvars.example
├── .gitignore
└── README.md
```

## Variables

| Name | Description | Default |
|------|-------------|---------|
| `aws_region` | AWS Region to deploy into | `eu-west-1` |
| `project_name` | Project name for resource naming | `lambda-microvm-demo` |
| `environment` | Environment tag | `demo` |
| `owner` | Owner tag | `youtube` |
| `image_name` | Lambda MicroVM image name | `youtube-http-api` |
| `base_image_name` | AWS-managed MicroVM base image | `al2023-1` |
| `base_image_version` | AWS-managed MicroVM base image version | `0` |
| `minimum_memory_mib` | Baseline memory for launched MicroVMs | `1024` |
| `app_source_dir` | Demo app folder to package | `apps/http-api` |
| `artifact_key` | S3 object key for the app zip | `artifacts/microvm-app.zip` |

## What This Deploys

1. An encrypted private S3 bucket for the MicroVM zip artifact.
2. A zip artifact built from the selected folder under `apps/`.
3. A CloudWatch Logs group for MicroVM image build logs.
4. An IAM build role that Lambda can assume.
5. A CloudFormation stack containing `AWS::Lambda::MicrovmImage`.

Terraform manages the image build path. Running MicroVM instances are launched with the AWS CLI because they are short-lived runtime sessions, not durable infrastructure.

## Demo Apps

| Demo | Folder | What it shows |
|------|--------|---------------|
| HTTP API | `apps/http-api` | A normal long-running HTTP service behind the MicroVM endpoint |
| System Info | `apps/system-info` | Container-style packaging with access to runtime, OS, process, and filesystem details |
| CPU Worker | `apps/cpu-worker` | Longer-running request work that would be awkward in a tiny request handler |
| AI Code Sandbox | `apps/ai-code-sandbox` | A practical AWS-style use case: execute AI-generated code in an isolated session |

To switch demos, change `terraform.tfvars`:

```hcl
image_name     = "youtube-cpu-worker"
app_source_dir = "apps/cpu-worker"
```

Then run:

```bash
terraform apply

# Launch the new image and copy the microvmId and endpoint from the response.
aws lambda-microvms run-microvm \
  --region "$REGION" \
  --image-identifier "$(terraform output -raw microvm_image_arn)" \
  --ingress-network-connectors "arn:aws:lambda:${REGION}:aws:network-connector:aws-network-connector:ALL_INGRESS" \
  --egress-network-connectors "arn:aws:lambda:${REGION}:aws:network-connector:aws-network-connector:INTERNET_EGRESS" \
  --idle-policy '{"autoResumeEnabled":true,"maxIdleDurationSeconds":900,"suspendedDurationSeconds":300}' \
  --maximum-duration-in-seconds 14400

MICROVM_ID="<new-microvm-id>"
ENDPOINT="<new-microvm-endpoint>"

TOKEN="$(aws lambda-microvms create-microvm-auth-token \
  --region "$REGION" \
  --microvm-identifier "$MICROVM_ID" \
  --expiration-in-minutes 30 \
  --allowed-ports '[{"port":8080}]' \
  --query authToken \
  --output text)"

curl "https://${ENDPOINT}/?iterations=500000" \
  -H "X-aws-proxy-auth: ${TOKEN}" \
  -H "X-aws-proxy-port: 8080"
```

For the AI sandbox use case, switch to:

```hcl
image_name     = "youtube-ai-code-sandbox"
app_source_dir = "apps/ai-code-sandbox"
```

Then run:

```bash
terraform apply

# Launch the sandbox image and copy the microvmId and endpoint from the response.
aws lambda-microvms run-microvm \
  --region "$REGION" \
  --image-identifier "$(terraform output -raw microvm_image_arn)" \
  --ingress-network-connectors "arn:aws:lambda:${REGION}:aws:network-connector:aws-network-connector:ALL_INGRESS" \
  --egress-network-connectors "arn:aws:lambda:${REGION}:aws:network-connector:aws-network-connector:INTERNET_EGRESS" \
  --idle-policy '{"autoResumeEnabled":true,"maxIdleDurationSeconds":900,"suspendedDurationSeconds":300}' \
  --maximum-duration-in-seconds 14400

MICROVM_ID="<new-microvm-id>"
ENDPOINT="<new-microvm-endpoint>"

TOKEN="$(aws lambda-microvms create-microvm-auth-token \
  --region "$REGION" \
  --microvm-identifier "$MICROVM_ID" \
  --expiration-in-minutes 30 \
  --allowed-ports '[{"port":8080}]' \
  --query authToken \
  --output text)"

curl "https://${ENDPOINT}/demo" \
  -H "X-aws-proxy-auth: ${TOKEN}" \
  -H "X-aws-proxy-port: 8080"
```

This demonstrates the kind of workload AWS calls out for Lambda MicroVMs: running user- or AI-generated code in a separate isolated environment per user or session. The sample app applies basic child-process limits, but production sandboxes also need strict networking, filesystem, package, observability, and abuse controls.

The helper scripts in `scripts/` wrap these same commands for repeat runs after the recording.

## Browser Access

The MicroVM endpoint requires custom auth headers, so a normal browser address bar cannot call it directly. Use the local proxy:

```bash
node scripts/browser-proxy.js <microvm-id>
```

Then open:

```text
http://localhost:8080
```

## Security Considerations

- The S3 artifact bucket blocks public access and uses server-side encryption.
- The build role can read only the generated artifact object.
- CloudWatch Logs permissions are scoped to the MicroVM build log group path.
- Runtime access requires a short-lived MicroVM auth token.
- The sample launch command uses AWS-managed public ingress and internet egress connectors for demo simplicity.
- Do not use the default `AdditionalOsCapabilities = ["ALL"]` for production without reviewing the capability requirements of your workload.
- The `ai-code-sandbox` app is a teaching demo. Do not expose arbitrary code execution without defense-in-depth controls around identity, network egress, package installation, filesystem access, rate limits, and audit logging.

## Estimated Cost

| Resource | Cost |
|---|---|
| S3 artifact bucket | Low storage cost |
| CloudWatch Logs | Charged by ingestion and retention |
| CloudFormation stack | No direct stack charge |
| Lambda MicroVM image build/storage | Charged according to Lambda MicroVM pricing |
| Running MicroVM session | Charged while running; terminate when finished |

Run `aws lambda-microvms terminate-microvm --region "$REGION" --microvm-identifier "$MICROVM_ID"` and `terraform destroy` when done.

## Troubleshooting

| Issue | Solution |
|-------|----------|
| `Invalid choice: lambda-microvms` | Update AWS CLI v2 and confirm `aws lambda-microvms help` works |
| `AccessDeniedException` in the wrong region | Add `--region "$(terraform output -raw aws_region)"` to AWS CLI commands |
| `Invalid ARN format` | Use `terraform output -raw microvm_image_arn`, not only the image name |
| Image stays building | Check the CloudWatch log group output and the CloudFormation stack events |
| Browser URL returns unauthorized | Use `scripts/browser-proxy.js` or send the required auth headers with curl/Postman |
