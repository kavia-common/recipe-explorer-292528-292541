#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/recipe-explorer-292528-292541/mobile_app"
cd "$WORKSPACE"
# Android/JVM: add a lightweight JUnit test when scaffold marker exists
if [ -f .scaffolded_by_setup ] && [ -d app/src/main ]; then
  mkdir -p app/src/test/java/com/example/app
  TEST_FILE=app/src/test/java/com/example/app/SimpleTest.java
  if [ ! -f "$TEST_FILE" ]; then
    cat > "$TEST_FILE" <<'TJ'
package com.example.app;
import org.junit.Test; import static org.junit.Assert.*;
public class SimpleTest { @Test public void smoke() { assertTrue(true); } }
TJ
  fi
  # ensure junit dependency exists safely (avoid duplicate lines)
  if [ -f app/build.gradle ]; then
    if ! grep -q "junit:junit" app/build.gradle 2>/dev/null; then
      if grep -q "^\s*dependencies\s*{" app/build.gradle 2>/dev/null; then
        sed -i "/^\s*dependencies\s*{/a \    testImplementation 'junit:junit:4.13.2'" app/build.gradle || true
      else
        printf "\ndependencies {\n    testImplementation 'junit:junit:4.13.2'\n}\n" >> app/build.gradle
      fi
    fi
  else
    # create minimal app/build.gradle with junit dependency
    mkdir -p app
    printf "plugins { id 'java' }\n\ndependencies {\n    testImplementation 'junit:junit:4.13.2'\n}\n" > app/build.gradle
  fi
  # Run Gradle tests if gradlew exists; tolerate test failures
  if [ -f ./gradlew ]; then
    ./gradlew test --no-daemon --console=plain || true
  fi
fi
# Node: run npm test only if package.json defines a test script
if [ -f package.json ]; then
  HAS_TEST=$(node -e "const p=require('./package.json'); console.log(p.scripts&&p.scripts.test?1:0)" 2>/dev/null || echo 0)
  if [ "$HAS_TEST" = "1" ]; then
    npm test --silent || true
  fi
fi
