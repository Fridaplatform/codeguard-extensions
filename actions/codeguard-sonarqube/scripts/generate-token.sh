#!/bin/bash
set -e

echo "Generating SonarQube token..."

TOKEN=$(curl -s -u admin:admin \
  -X POST "http://localhost:9000/api/user_tokens/generate" \
  -d "name=ci-token-$(date +%s)" | jq -r '.token')

if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
  echo "Failed to generate Sonar token"
  exit 1
fi

echo "SONAR_TOKEN=$TOKEN" >> "$GITHUB_ENV"

echo "Sonar token generated successfully"