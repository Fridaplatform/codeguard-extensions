#!/bin/bash
set -e

PROJECT_KEY="$1"

if [ -z "$PROJECT_KEY" ]; then
  echo "projectKey is required"
  exit 1
fi

echo "Waiting for SonarQube background task..."

REPORT_FILE="$GITHUB_WORKSPACE/.scanner-meta/report-task.txt"

if [ ! -f "$REPORT_FILE" ]; then
  echo "report-task.txt not found"
  find "$GITHUB_WORKSPACE" -maxdepth 5 -type f | sort | grep report-task || true
  exit 1
fi

CE_TASK_ID=$(grep ceTaskId "$REPORT_FILE" | cut -d= -f2)

if [ -z "$CE_TASK_ID" ]; then
  echo "Could not get ceTaskId"
  cat "$REPORT_FILE" || true
  exit 1
fi

echo "CE Task ID: $CE_TASK_ID"

for i in {1..60}; do
  STATUS=$(curl -s -u "$SONAR_TOKEN:" \
    "http://localhost:9000/api/ce/task?id=$CE_TASK_ID" | jq -r '.task.status')

  echo "Current CE status: $STATUS"

  if [ "$STATUS" = "SUCCESS" ]; then
    echo "SonarQube background task finished successfully"
    break
  fi

  if [ "$STATUS" = "FAILED" ] || [ "$STATUS" = "CANCELED" ]; then
    echo "SonarQube background task failed with status: $STATUS"
    exit 1
  fi

  sleep 5
done

mkdir -p sonar-results
ISSUES_JSON="[]"

PAGE=1
while true; do
  RESP=$(curl -s -u "$SONAR_TOKEN:" \
    "http://localhost:9000/api/issues/search?projectKeys=$PROJECT_KEY&resolved=false&p=$PAGE&ps=500")

  COUNT=$(echo "$RESP" | jq '.issues | length')
  [ "$COUNT" -eq 0 ] && break

  ISSUES_JSON=$(jq --argjson new "$(echo "$RESP" | jq '.issues')" \
    '. + $new' <<< "$ISSUES_JSON")

  PAGE=$((PAGE+1))
done

echo "$ISSUES_JSON" > sonar-results/issues.json

echo "Extracted issues:"
jq 'length' sonar-results/issues.json