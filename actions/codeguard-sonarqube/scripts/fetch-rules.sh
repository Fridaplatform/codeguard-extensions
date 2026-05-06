#!/bin/bash
set -e

TEAM_ID="$1"
RULES_API_URL="$2"

if [ -z "$TEAM_ID" ]; then
  echo "teamId is required"
  exit 1
fi

if [ -z "$RULES_API_URL" ]; then
  echo "rulesApiUrl is required"
  exit 1
fi

echo "Fetching CodeGuard Sonar rules for team: $TEAM_ID"

RESPONSE=$(curl -s -X POST "$RULES_API_URL" \
  -H "Content-Type: application/json" \
  -H "User-Agent: github-action" \
  -d "{
    \"installationId\": \"128498765\",
    \"teamId\": \"$TEAM_ID\"
  }")

echo "$RESPONSE" > rules-response.json

echo "Rules response:"
cat rules-response.json

ERROR_FLAG=$(jq -r '.error // false' rules-response.json)

if [ "$ERROR_FLAG" != "false" ] && [ "$ERROR_FLAG" != "null" ]; then
  echo "Failed to get rules from CodeGuard API"
  jq . rules-response.json || cat rules-response.json
  exit 1
fi

echo "Rules fetched successfully"