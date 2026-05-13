#!/bin/bash
set -e

TEAM_ID="$1"
INSTALLATION_ID="$2"
RULES_API_URL="$3"

if [ -z "$TEAM_ID" ]; then
  echo "teamId is required"
  exit 1
fi

if [ -z "$INSTALLATION_ID" ]; then
  echo "installationId is required"
  exit 1
fi

if [ -z "$RULES_API_URL" ]; then
  echo "rulesApiUrl is required"
  exit 1
fi

echo "Fetching CodeGuard Sonar rules for team: $TEAM_ID"
echo "Using installation: $INSTALLATION_ID"

RESPONSE=$(curl -s -X POST "$RULES_API_URL" \
  -H "Content-Type: application/json" \
  -d "{
    \"teamId\": \"$TEAM_ID\",
    \"installationId\": \"$INSTALLATION_ID\"
  }")

echo "$RESPONSE" > rules-response.json

echo "Rules response:"
cat rules-response.json

API_ERROR=$(jq -r '.error // false' rules-response.json)
DATA_ERROR=$(jq -r '.data.error // false' rules-response.json)
MSG=$(jq -r '.data.msg // .msg // "Unknown error"' rules-response.json)

if [ "$API_ERROR" = "true" ] || [ "$DATA_ERROR" = "true" ]; then
  echo "Error fetching CodeGuard rules: $MSG"
  jq . rules-response.json || cat rules-response.json
  exit 1
fi

DATA=$(jq '.data.data // .data' rules-response.json)

if [ "$DATA" = "null" ]; then
  echo "Rules data is null"
  jq . rules-response.json || cat rules-response.json
  exit 1
fi

echo "$DATA" > rules.json

echo "Rules fetched successfully"