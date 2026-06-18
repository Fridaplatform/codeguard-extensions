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

map_language_to_sonar_key() {
  case "$1" in
    JavaScript|javascript|JS|js)
      echo "js"
      ;;
    TypeScript|typescript|TS|ts)
      echo "ts"
      ;;
    Python|python|PY|py)
      echo "py"
      ;;
    Java|java)
      echo "java"
      ;;
    CSharp|csharp|C#|cs)
      echo "cs"
      ;;
    *)
      echo "$1"
      ;;
  esac
}

for LANG in $LANGUAGES
do
  SONAR_LANG=$(map_language_to_sonar_key "$LANG")
  PROFILE_NAME="CodeGuard ${SONAR_LANG^^} Profile"

  echo "Processing language: $LANG"
  echo "SonarQube language key: $SONAR_LANG"
  echo "Creating profile: $PROFILE_NAME"

  RULE_COUNT=$(jq -r "$RULES_PATH[\"$LANG\"] // [] | length" rules-response.json)

  if [ "$RULE_COUNT" -eq 0 ]; then
    echo "No rules found for language $LANG"
    continue
  fi

  curl -s -u "$SONAR_TOKEN:" -X POST \
    "http://localhost:9000/api/qualityprofiles/create" \
    -d "language=$SONAR_LANG" \
    -d "name=$PROFILE_NAME" || true

  PROFILE_KEY=$(curl -s -u "$SONAR_TOKEN:" \
    "http://localhost:9000/api/qualityprofiles/search?language=$SONAR_LANG" | \
    jq -r --arg NAME "$PROFILE_NAME" '.profiles[] | select(.name==$NAME) | .key')

  if [ -z "$PROFILE_KEY" ] || [ "$PROFILE_KEY" = "null" ]; then
    echo "Could not find profile key for $SONAR_LANG"
    exit 1
  fi

  echo "Profile key for $SONAR_LANG: $PROFILE_KEY"

  for (( j=0; j<RULE_COUNT; j++ ))
  do
    RULE=$(jq -r "$RULES_PATH[\"$LANG\"][$j]" rules-response.json)

    if [ -z "$RULE" ] || [ "$RULE" = "null" ]; then
      echo "Invalid rule found for $LANG at index $j"
      exit 1
    fi

    echo "Activating rule for $SONAR_LANG: $RULE"

    curl -s -u "$SONAR_TOKEN:" -X POST \
      "http://localhost:9000/api/qualityprofiles/activate_rule" \
      -d "key=$PROFILE_KEY" \
      -d "rule=$RULE" \
      -d "language=$SONAR_LANG"
  done

  echo "Setting default profile for $SONAR_LANG"

  curl -s -u "$SONAR_TOKEN:" -X POST \
    "http://localhost:9000/api/qualityprofiles/set_default" \
    -d "language=$SONAR_LANG" \
    -d "qualityProfile=$PROFILE_NAME"

done

echo "SonarQube profiles configured successfully"