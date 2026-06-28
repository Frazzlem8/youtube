#!/usr/bin/env bash
set -euo pipefail

MICROVM_ID="${1:?Usage: ./scripts/terminate-microvm.sh <microvm-id>}"
REGION="${AWS_REGION:-$(terraform output -raw aws_region)}"

aws lambda-microvms terminate-microvm \
  --region "$REGION" \
  --microvm-identifier "$MICROVM_ID"
