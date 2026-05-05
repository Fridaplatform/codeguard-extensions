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

echo "Fetching CodeGuard rules for team: $TEAM_ID"

RESPONSE=$(curl -s -X POST "$RULES_API_URL" \
  -H "Content-Type: application/json" \
  -d "{
    \"data\": {
      \"team_id\": \"$TEAM_ID\"
    }
  }")

echo "$RESPONSE" > rules-response.json

echo "Rules response:"
cat rules-response.json

ERROR_FLAG=$(jq -r '.result.error' rules-response.json)

if [ "$ERROR_FLAG" != "false" ]; then
  echo "Failed to get rules from CodeGuard API"
  jq . rules-response.json || cat rules-response.json
  exit 1
fi

echo "Rules fetched successfully"