#!/bin/bash
set -e

echo "Starting ephemeral SonarQube..."

docker run -d \
  --name sonar-ephemeral \
  -p 9000:9000 \
  -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true \
  sonarqube:community

echo "Waiting for SonarQube..."

for i in {1..60}; do
  STATUS=$(curl -s http://localhost:9000/api/system/status | jq -r '.status' || echo "")

  if [ "$STATUS" = "UP" ]; then
    echo "SonarQube is UP"
    exit 0
  fi

  echo "Current status: $STATUS"
  sleep 5
done

echo "SonarQube failed to start"
exit 1