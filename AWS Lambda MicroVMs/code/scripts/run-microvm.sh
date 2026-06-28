#!/usr/bin/env bash
set -euo pipefail

if ! aws lambda-microvms help >/dev/null 2>&1; then
  cat >&2 <<'ERROR'
Your installed AWS CLI does not include the lambda-microvms command.

Install or update AWS CLI v2, then retry.
ERROR
  exit 1
fi

IMAGE_ARN="${1:-$(terraform output -raw microvm_image_arn)}"
REGION="${AWS_REGION:-$(terraform output -raw aws_region)}"

aws lambda-microvms run-microvm \
  --region "$REGION" \
  --image-identifier "$IMAGE_ARN" \
  --ingress-network-connectors "arn:aws:lambda:${REGION}:aws:network-connector:aws-network-connector:ALL_INGRESS" \
  --egress-network-connectors "arn:aws:lambda:${REGION}:aws:network-connector:aws-network-connector:INTERNET_EGRESS" \
  --idle-policy '{"autoResumeEnabled":true,"maxIdleDurationSeconds":900,"suspendedDurationSeconds":300}' \
  --maximum-duration-in-seconds 14400
