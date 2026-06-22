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
  if [ -n "$GITHUB_BASE_REF" ]; then
    NEW_CODE_REFERENCE_BRANCH="$GITHUB_BASE_REF"
  else
    NEW_CODE_REFERENCE_BRANCH="main"
  fi
fi

echo "Running Sonar Scanner..."
echo "Project key: $PROJECT_KEY"
echo "Sources: $SOURCES"
echo "Exclusions: $EXCLUSIONS"
echo "New Code reference branch: $NEW_CODE_REFERENCE_BRANCH"

mkdir -p "$GITHUB_WORKSPACE/.scanner-meta"
chmod -R 777 "$GITHUB_WORKSPACE/.scanner-meta"

if find "$GITHUB_WORKSPACE" \( -name "*.csproj" -o -name "*.sln" \) | grep -q .; then
  echo "Detected .NET project. Using SonarScanner for .NET..."

  docker run --rm \
    --platform=linux/amd64 \
    --network host \
    -u 0:0 \
    -e SONAR_TOKEN="$SONAR_TOKEN" \
    -v "$GITHUB_WORKSPACE:/usr/src" \
    -w /usr/src \
    mcr.microsoft.com/dotnet/sdk:8.0 \
    bash -c "
      set -e
      dotnet tool install --global dotnet-sonarscanner
      export PATH=\"\$PATH:/root/.dotnet/tools\"

      dotnet sonarscanner begin \
        /k:\"$PROJECT_KEY\" \
        /d:sonar.host.url=\"http://localhost:9000\" \
        /d:sonar.token=\"$SONAR_TOKEN\" \
        /d:sonar.scanner.metadataFilePath=\"/usr/src/.scanner-meta/report-task.txt\" \
        /d:sonar.exclusions=\"$EXCLUSIONS\" \
        /d:sonar.newCode.referenceBranch=\"$NEW_CODE_REFERENCE_BRANCH\" \
        /d:sonar.verbose=true

      PROJECT_FILE=\$(find /usr/src \( -name \"*.sln\" -o -name \"*.csproj\" \) | head -n 1)

      if [ -z \"\$PROJECT_FILE\" ]; then
        echo \"No .sln or .csproj file found\"
        exit 1
      fi

      echo \"Building .NET project: \$PROJECT_FILE\"
      dotnet build \"\$PROJECT_FILE\"

      dotnet sonarscanner end \
        /d:sonar.token=\"$SONAR_TOKEN\"
    "

else
  JAVA_BINARIES=""

  if find "$GITHUB_WORKSPACE" -name "*.java" | grep -q .; then
    echo "Detected Java files. Preparing Java binaries for analysis..."

    docker run --rm \
      --platform=linux/amd64 \
      -u 0:0 \
      -v "$GITHUB_WORKSPACE:/usr/src" \
      -w /usr/src \
      maven:3.9-eclipse-temurin-17 \
      bash -c "
        set -e

        if [ -f \"pom.xml\" ]; then
          echo \"Detected Maven project. Running mvn compile...\"
          ./mvnw compile || mvn compile
        elif [ -f \"gradlew\" ]; then
          echo \"Detected Gradle wrapper. Running ./gradlew classes...\"
          chmod +x ./gradlew
          ./gradlew classes
        elif [ -f \"build.gradle\" ] || [ -f \"build.gradle.kts\" ]; then
          echo \"Detected Gradle project. Running gradle classes...\"
          gradle classes
        else
          echo \"No Maven or Gradle project detected. Compiling Java files with javac fallback...\"
          mkdir -p /usr/src/target/classes
          javac -d /usr/src/target/classes \$(find /usr/src -name \"*.java\")
        fi
      "

    JAVA_BINARIES="-Dsonar.java.binaries=/usr/src/target/classes"
  fi

  echo "Using generic sonar-scanner-cli..."

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
    -Dsonar.verbose=true \
    $JAVA_BINARIES
fi

echo "Sonar Scanner finished"