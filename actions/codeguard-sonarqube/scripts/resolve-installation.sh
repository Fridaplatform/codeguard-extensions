#!/bin/bash
set -e

RESOLVE_INSTALLATION_API_URL="$1"

if [ -z "$RESOLVE_INSTALLATION_API_URL" ]; then
  echo "resolveInstallationApiUrl is required"
  exit 1
fi

if [ -z "$GITHUB_REPOSITORY" ]; then
  echo "GITHUB_REPOSITORY is not available"
  exit 1
fi

OWNER="${GITHUB_REPOSITORY%%/*}"

echo "Resolving GitHub installation for owner: $OWNER"

RESPONSE=$(curl -s -X POST "$RESOLVE_INSTALLATION_API_URL" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -d "{
    \"owner\": \"$OWNER\"
  }")

echo "Resolve installation response:"
echo "$RESPONSE"

ERROR=$(echo "$RESPONSE" | jq -r '.data.error // .error // false')
MSG=$(echo "$RESPONSE" | jq -r '.data.msg // .msg // "Unknown error"')

if [ "$ERROR" = "true" ]; then
  echo "Failed to resolve GitHub installation: $MSG"
  exit 1
fi

INSTALLATION_ID=$(echo "$RESPONSE" | jq -r '.data.data.installationId // .data.installationId')

if [ -z "$INSTALLATION_ID" ] || [ "$INSTALLATION_ID" = "null" ]; then
  echo "Could not resolve installationId"
  exit 1
fi

echo "Resolved installation ID: $INSTALLATION_ID"

echo "CODEGUARD_INSTALLATION_ID=$INSTALLATION_ID" >> "$GITHUB_ENV"