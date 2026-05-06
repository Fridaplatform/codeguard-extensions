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
echo "Top issues:" >> sonar-results/summary.md
echo "" >> sonar-results/summary.md

echo "Summary generated"
cat sonar-results/summary.md