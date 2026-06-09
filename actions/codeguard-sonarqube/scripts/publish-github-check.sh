#!/bin/bash
set -e

ISSUES_FILE="${1:-sonar-results/issues.json}"
SUMMARY_FILE="${2:-sonar-results/summary.md}"

CHECK_NAME="${CHECK_NAME:-CodeGuard SonarQube Analysis}"
API_URL="https://api.github.com/repos/$GITHUB_REPOSITORY/check-runs"
DETAILS_URL="${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"

if [ -z "$GITHUB_TOKEN" ]; then
  echo "GITHUB_TOKEN is required"
  exit 1
fi

if [ -z "$GITHUB_REPOSITORY" ]; then
  echo "GITHUB_REPOSITORY is required"
  exit 1
fi

if [ -z "$GITHUB_SHA" ]; then
  echo "GITHUB_SHA is required"
  exit 1
fi

if [ ! -f "$ISSUES_FILE" ]; then
  echo "Issues file not found: $ISSUES_FILE"
  echo "[]" > "$ISSUES_FILE"
fi

if [ -f "$SUMMARY_FILE" ]; then
  SUMMARY=$(head -c 60000 "$SUMMARY_FILE")
else
  SUMMARY="SonarQube analysis completed."
fi

ISSUE_COUNT=$(jq 'length' "$ISSUES_FILE")

if [ "$ISSUE_COUNT" -eq 0 ]; then
  CONCLUSION="success"
  TITLE="CodeGuard SonarQube Analysis passed"
else
  CONCLUSION="failure"
  TITLE="CodeGuard SonarQube Analysis found $ISSUE_COUNT issue(s)"
fi

echo "Creating GitHub Check Run..."
echo "Issues found: $ISSUE_COUNT"

ANNOTATIONS_FILE="$(mktemp)"
trap 'rm -f "$ANNOTATIONS_FILE"' EXIT

jq '
  map(select(.line != null))
  | map({
    path: (.component | split(":") | .[1]),
    start_line: (.line | tonumber),
    end_line: (.line | tonumber),
    start_column: 1,
    end_column: 1,
    annotation_level:
      (if .severity == "BLOCKER" or .severity == "CRITICAL" or .severity == "MAJOR"
       then "failure"
       else "warning"
       end),
    title: (.rule // "SonarQube issue"),
    message: (.message // "SonarQube issue")
  })
  | map(select(.path != null and .path != ""))
' "$ISSUES_FILE" > "$ANNOTATIONS_FILE"

echo "Annotations payload:"
jq . "$ANNOTATIONS_FILE"

FIRST_ANNOTATIONS=$(jq '.[0:50]' "$ANNOTATIONS_FILE")

CHECK_PAYLOAD=$(jq -n \
  --arg name "$CHECK_NAME" \
  --arg head_sha "$GITHUB_SHA" \
  --arg conclusion "$CONCLUSION" \
  --arg title "$TITLE" \
  --arg summary "$SUMMARY" \
  --arg details_url "$DETAILS_URL" \
  --argjson annotations "$FIRST_ANNOTATIONS" \
  '{
    name: $name,
    head_sha: $head_sha,
    status: "completed",
    conclusion: $conclusion,
    details_url: $details_url,
    output: {
      title: $title,
      summary: $summary,
      annotations: $annotations
    }
  }')

CHECK_RESPONSE=$(curl -sSf -X POST "$API_URL" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  -d "$CHECK_PAYLOAD")

CHECK_RUN_ID=$(echo "$CHECK_RESPONSE" | jq -r '.id // empty')

if [ -z "$CHECK_RUN_ID" ]; then
  echo "Could not create check run"
  echo "$CHECK_RESPONSE" | jq .
  exit 1
fi

echo "Created Check Run ID: $CHECK_RUN_ID"

TOTAL_ANNOTATIONS=$(jq 'length' "$ANNOTATIONS_FILE")
echo "Publishing annotations: $TOTAL_ANNOTATIONS"

if [ "$TOTAL_ANNOTATIONS" -le 50 ]; then
  echo "All annotations were published in the initial check run."
  echo "GitHub Check published successfully."
  exit 0
fi

START=50
BATCH_SIZE=50

while [ "$START" -lt "$TOTAL_ANNOTATIONS" ]; do
  BATCH=$(jq ".[$START:$START+$BATCH_SIZE]" "$ANNOTATIONS_FILE")

  UPDATE_PAYLOAD=$(jq -n \
    --arg title "$TITLE" \
    --arg summary "$SUMMARY" \
    --argjson annotations "$BATCH" \
    '{
      output: {
        title: $title,
        summary: $summary,
        annotations: $annotations
      }
    }')

  echo "Uploading annotations $START to $((START + BATCH_SIZE))..."

  curl -sSf -X PATCH "$API_URL/$CHECK_RUN_ID" \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    -d "$UPDATE_PAYLOAD" | jq '.id'

  START=$((START + BATCH_SIZE))
done

echo "GitHub Check published successfully."