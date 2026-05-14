#!/bin/bash
set -e

if [ ! -f "sonar-results/issues.json" ]; then
  echo "sonar-results/issues.json not found"
  exit 1
fi

echo "Generating issue summary..."

jq '
  group_by(.type) |
  map({
    type: .[0].type,
    count: length,
    critical: map(select(.severity=="CRITICAL")) | length,
    major: map(select(.severity=="MAJOR")) | length
  })
' sonar-results/issues.json > sonar-results/summary.json

echo "## SonarQube Analysis Results" > sonar-results/summary.md
echo "" >> sonar-results/summary.md

jq -r '.[] |
  "- **\(.type)**: \(.count) (CRITICAL: \(.critical), MAJOR: \(.major))"
' sonar-results/summary.json >> sonar-results/summary.md

echo "" >> sonar-results/summary.md
echo "## Top issues" >> sonar-results/summary.md
echo "" >> sonar-results/summary.md

ISSUES_COUNT=$(jq 'length' sonar-results/issues.json)

if [ "$ISSUES_COUNT" -eq 0 ]; then
  echo "No issues found." >> sonar-results/summary.md
else
  jq -r '
    sort_by(
      if .severity == "BLOCKER" then 0
      elif .severity == "CRITICAL" then 1
      elif .severity == "MAJOR" then 2
      elif .severity == "MINOR" then 3
      else 4
      end
    )
    | .[0:10]
    | to_entries[]
    | "\(.key + 1). **\(.value.severity)** \(.value.type) - \(.value.message)\n   - File: `\(.value.component)`\n   - Rule: `\(.value.rule)`\n"
  ' sonar-results/issues.json >> sonar-results/summary.md
fi

echo "Summary generated"
cat sonar-results/summary.md