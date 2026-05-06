#!/bin/bash
set -e

echo "Configuring SonarQube quality profiles dynamically..."

if [ ! -f "rules-response.json" ]; then
  echo "rules-response.json not found"
  exit 1
fi

RULES_PATH='(.data.data // .data // .result.data)'

LANGUAGES=$(jq -r "$RULES_PATH | keys[]" rules-response.json)

if [ -z "$LANGUAGES" ]; then
  echo "No languages found in rules response"
  cat rules-response.json
  exit 1
fi

for LANG in $LANGUAGES
do
  PROFILE_NAME="CodeGuard ${LANG^^} Profile"

  echo "Processing language: $LANG"
  echo "Creating profile: $PROFILE_NAME"

  curl -s -u "$SONAR_TOKEN:" -X POST \
    "http://localhost:9000/api/qualityprofiles/create" \
    -d "language=$LANG" \
    -d "name=$PROFILE_NAME" || true

  PROFILE_KEY=$(curl -s -u "$SONAR_TOKEN:" \
    "http://localhost:9000/api/qualityprofiles/search?language=$LANG" | \
    jq -r --arg NAME "$PROFILE_NAME" '.profiles[] | select(.name==$NAME) | .key')

  if [ -z "$PROFILE_KEY" ] || [ "$PROFILE_KEY" = "null" ]; then
    echo "Could not find profile key for $LANG"
    exit 1
  fi

  echo "Profile key for $LANG: $PROFILE_KEY"

  RULE_COUNT=$(jq -r "$RULES_PATH[\"$LANG\"] // [] | length" rules-response.json)

  if [ "$RULE_COUNT" -eq 0 ]; then
    echo "No rules found for language $LANG"
    continue
  fi

  for (( j=0; j<RULE_COUNT; j++ ))
  do
    RULE=$(jq -r "$RULES_PATH[\"$LANG\"][$j]" rules-response.json)

    if [ -z "$RULE" ] || [ "$RULE" = "null" ]; then
      echo "Invalid rule found for $LANG at index $j"
      exit 1
    fi

    echo "Activating rule for $LANG: $RULE"

    curl -s -u "$SONAR_TOKEN:" -X POST \
      "http://localhost:9000/api/qualityprofiles/activate_rule" \
      -d "key=$PROFILE_KEY" \
      -d "rule=$RULE" \
      -d "language=$LANG"
  done

  echo "Setting default profile for $LANG"

  curl -s -u "$SONAR_TOKEN:" -X POST \
    "http://localhost:9000/api/qualityprofiles/set_default" \
    -d "language=$LANG" \
    -d "qualityProfile=$PROFILE_NAME"

done

echo "SonarQube profiles configured successfully"