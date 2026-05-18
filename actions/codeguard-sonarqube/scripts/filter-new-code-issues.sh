#!/bin/bash
set -e

BASE_BRANCH="$1"

if [ -z "$BASE_BRANCH" ]; then
  BASE_BRANCH="main"
fi

echo "Filtering issues by PR diff..."
echo "Base branch: $BASE_BRANCH"

git fetch origin "$BASE_BRANCH"

CHANGED_FILES=$(git diff --name-only "origin/$BASE_BRANCH"...HEAD)

echo "Changed files:"
echo "$CHANGED_FILES"

if [ ! -f "sonar-results/issues.json" ]; then
  echo "sonar-results/issues.json not found"
  exit 1
fi

TMP_FILE=$(mktemp)

jq --argfiles changed <(
  printf '%s\n' "$CHANGED_FILES" | jq -R . | jq -s .
) '
[
  .[]
  | select(
      .component as $component
      | ($changed[0][] | split("/") | last) as $file
      | ($component | endswith($file))
    )
]
' sonar-results/issues.json > "$TMP_FILE"

mv "$TMP_FILE" sonar-results/issues.json

echo "Filtered issues count:"
jq 'length' sonar-results/issues.json