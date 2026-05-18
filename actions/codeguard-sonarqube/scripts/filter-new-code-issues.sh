#!/bin/bash
set -e

BASE_BRANCH="$1"

if [ -z "$BASE_BRANCH" ]; then
  BASE_BRANCH="main"
fi

echo "Filtering issues by PR diff..."
echo "Base branch: $BASE_BRANCH"

if [ ! -f "sonar-results/issues.json" ]; then
  echo "sonar-results/issues.json not found"
  exit 1
fi

git fetch origin "$BASE_BRANCH"

CHANGED_FILES_FILE="$(mktemp)"
TMP_FILE="$(mktemp)"

git diff --name-only "origin/$BASE_BRANCH"...HEAD > "$CHANGED_FILES_FILE"

echo "Changed files:"
cat "$CHANGED_FILES_FILE"

jq -R -s '
  split("\n")
  | map(select(length > 0))
' "$CHANGED_FILES_FILE" > "$CHANGED_FILES_FILE.json"

jq --slurpfile changed "$CHANGED_FILES_FILE.json" '
[
  .[]
  | select(
      (.component | split(":") | last) as $issueFile
      | ($changed[0] | index($issueFile))
    )
]
' sonar-results/issues.json > "$TMP_FILE"

mv "$TMP_FILE" sonar-results/issues.json

echo "Filtered issues count:"
jq 'length' sonar-results/issues.json