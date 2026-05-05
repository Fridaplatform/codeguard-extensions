#!/bin/bash
set -e

PROJECT_KEY="$1"

if [ -z "$PROJECT_KEY" ]; then
  echo "projectKey is required"
  exit 1
fi

echo "Checking Quality Gate..."

STATUS=$(curl -s -u "$SONAR_TOKEN:" \
  "http://localhost:9000/api/qualitygates/project_status?projectKey=$PROJECT_KEY" \
  | jq -r '.projectStatus.status')

echo "Quality Gate status: $STATUS"

if [ "$STATUS" != "OK" ]; then
  echo "SonarQube Quality Gate failed"
  exit 1
fi

echo "Quality Gate passed"