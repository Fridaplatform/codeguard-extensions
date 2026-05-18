#!/bin/bash
set -e

PROJECT_KEY="$1"
SOURCES="$2"
EXCLUSIONS="$3"
NEW_CODE_REFERENCE_BRANCH="$4"

if [ -z "$PROJECT_KEY" ]; then
  echo "projectKey is required"
  exit 1
fi

if [ -z "$SOURCES" ]; then
  SOURCES="/usr/src"
fi

if [ -z "$EXCLUSIONS" ]; then
  EXCLUSIONS="**/node_modules/**,**/dist/**,**/build/**,**/__pycache__/**"
fi

if [ -z "$NEW_CODE_REFERENCE_BRANCH" ]; then
  NEW_CODE_REFERENCE_BRANCH="main"
fi

echo "Running Sonar Scanner..."
echo "Project key: $PROJECT_KEY"
echo "Sources: $SOURCES"
echo "Exclusions: $EXCLUSIONS"
echo "New Code reference branch: $NEW_CODE_REFERENCE_BRANCH"

mkdir -p "$GITHUB_WORKSPACE/.scanner-meta"
chmod -R 777 "$GITHUB_WORKSPACE/.scanner-meta"

docker run --rm \
  --platform=linux/amd64 \
  --network host \
  -u 0:0 \
  -e SONAR_TOKEN="$SONAR_TOKEN" \
  -v "$GITHUB_WORKSPACE:/usr/src" \
  sonarsource/sonar-scanner-cli \
  -Dsonar.projectKey="$PROJECT_KEY" \
  -Dsonar.projectBaseDir=/usr/src \
  -Dsonar.working.directory=/tmp/.scannerwork \
  -Dsonar.scanner.metadataFilePath=/usr/src/.scanner-meta/report-task.txt \
  -Dsonar.sources="$SOURCES" \
  -Dsonar.exclusions="$EXCLUSIONS" \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.login="$SONAR_TOKEN" \
  -Dsonar.newCode.referenceBranch="$NEW_CODE_REFERENCE_BRANCH" \
  -Dsonar.verbose=true

echo "Sonar Scanner finished"