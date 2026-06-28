#!/usr/bin/env bash
set -euo pipefail

MICROVM_ID="${1:?Usage: ./scripts/call-microvm.sh <microvm-id> [path]}"
PATH_TO_CALL="${2:-/}"
REGION="${AWS_REGION:-$(terraform output -raw aws_region)}"

MICROVM_JSON="$(aws lambda-microvms get-microvm \
  --region "$REGION" \
  --microvm-identifier "$MICROVM_ID")"

ENDPOINT="$(printf '%s' "$MICROVM_JSON" | python3 -c 'import json,sys; print(json.load(sys.stdin)["endpoint"])')"

TOKEN="$(aws lambda-microvms create-microvm-auth-token \
  --region "$REGION" \
  --microvm-identifier "$MICROVM_ID" \
  --expiration-in-minutes 30 \
  --allowed-ports '[{"port":8080}]' \
  --query authToken \
  --output text)"

curl "https://${ENDPOINT}${PATH_TO_CALL}" \
  -H "X-aws-proxy-auth: ${TOKEN}" \
  -H "X-aws-proxy-port: 8080"
