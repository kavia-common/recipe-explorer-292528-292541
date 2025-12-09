#!/usr/bin/env bash
set -euo pipefail
# Validation: build APK, synthetic start/stop, capture evidence
WORKSPACE="/home/kavia/workspace/code-generation/recipe-explorer-292528-292541/mobile_app"
cd "$WORKSPACE"
[ -f ./gradlew ] || { echo "No gradlew; cannot build" >&2; exit 2; }
# record gradle and java versions
./gradlew --version > build_gradle_version.txt 2>&1 || true
java -version > build_java_version.txt 2>&1 || true
# run build and capture logs
./gradlew assembleDebug --no-daemon --console=plain > build_stdout.log 2>&1 || { echo "gradle build failed; see build_stdout.log" >&2; exit 3; }
APK_PATH=$(find "$WORKSPACE" -path "*/app/build/outputs/apk/debug/*.apk" -print -quit || true)
[ -n "$APK_PATH" ] || { echo "APK not found after build" >&2; exit 4; }
# Synthetic start: inspect APK
TMPD=$(mktemp -d)
unzip -q "$APK_PATH" -d "$TMPD" || { echo "unzip apk failed" >&2; rm -rf "$TMPD"; exit 5; }
[ -f "$TMPD/classes.dex" ] || { echo "classes.dex missing in APK" >&2; rm -rf "$TMPD"; exit 6; }
# attempt aapt if available under installed build-tools
AAPT_PATH=""
if command -v aapt >/dev/null 2>&1; then AAPT_PATH=$(command -v aapt); else
  # search build-tools folders
  if [ -n "${ANDROID_SDK_ROOT:-}" ]; then
    for b in "$ANDROID_SDK_ROOT"/build-tools/*/aapt; do [ -x "$b" ] && AAPT_PATH="$b" && break; done
  fi
fi
if [ -n "$AAPT_PATH" ]; then
  # aapt may output binary xml; dump xmltree (best-effort)
  "$AAPT_PATH" dump xmltree "$APK_PATH" AndroidManifest.xml > manifest_dump.txt 2>/dev/null || true
else
  # fallback to the extracted AndroidManifest.xml
  if [ -f "$TMPD/AndroidManifest.xml" ]; then
    head -n 200 "$TMPD/AndroidManifest.xml" > manifest_dump.txt || true
  else
    # Some APKs have manifest under /AndroidManifest.xml or in META-INF; try find
    if find "$TMPD" -maxdepth 2 -type f -name AndroidManifest.xml -print -quit >/dev/null 2>&1; then
      find "$TMPD" -type f -name AndroidManifest.xml -print -quit | xargs -r head -n 200 > manifest_dump.txt || true
    fi
  fi
fi
# checksum
if command -v sha256sum >/dev/null 2>&1; then CHECKSUM=$(sha256sum "$APK_PATH" | awk '{print $1}'); else CHECKSUM="unknown"; fi
# collect test results if any
TEST_RESULTS_DIR="$WORKSPACE/app/build/test-results"
[ -d "$TEST_RESULTS_DIR" ] && tar -czf test_results.tar.gz -C "$WORKSPACE" "app/build/test-results" || true
# evidence output for CI
echo "BUILD_OK:$APK_PATH"
echo "APK_SHA256=$CHECKSUM"
echo "BUILD_LOG=$WORKSPACE/build_stdout.log"
echo "GRADLE_INFO=$WORKSPACE/build_gradle_version.txt"
echo "JAVA_INFO=$WORKSPACE/build_java_version.txt"
echo "MANIFEST_DUMP=$WORKSPACE/manifest_dump.txt"
[ -d "$TEST_RESULTS_DIR" ] && echo "TEST_RESULTS=$WORKSPACE/test_results.tar.gz"
# cleanup
rm -rf "$TMPD"
./gradlew clean --no-daemon >/dev/null || true
exit 0
