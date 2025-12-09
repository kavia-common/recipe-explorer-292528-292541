#!/usr/bin/env bash
set -euo pipefail

# Scaffolding: create minimal Android project and generate reliable gradle wrapper
WORKSPACE="/home/kavia/workspace/code-generation/recipe-explorer-292528-292541/mobile_app"
mkdir -p "$WORKSPACE" && cd "$WORKSPACE"
# idempotent: skip if already scaffolded or project files exist
if [ -f "$WORKSPACE/.scaffolded_by_setup" ] || [ -f "$WORKSPACE/gradlew" ] || [ -f "$WORKSPACE/settings.gradle" ]; then exit 0; fi

mkdir -p app/src/main/java/com/example/app app/src/main/res/layout app/src/main/res/values

cat > settings.gradle <<'SG'
rootProject.name = 'mobile_app'
include ':app'
SG

# top-level buildscript that supplies AGP compatible with Gradle 8.x
cat > build.gradle <<'BG'
buildscript { repositories { google(); mavenCentral() }
  dependencies { classpath 'com.android.tools.build:gradle:8.1.2' }
}
allprojects { repositories { google(); mavenCentral() } }
BG

# app module compatible with AGP 8.x (Groovy DSL minimal)
cat > app/build.gradle <<'ABG'
apply plugin: 'com.android.application'
android {
  compileSdkVersion 33
  defaultConfig { applicationId "com.example.app"; minSdkVersion 21; targetSdkVersion 33; versionCode 1; versionName "0.1" }
  buildTypes { release { minifyEnabled false } }
}
dependencies { testImplementation 'junit:junit:4.13.2' }
ABG

cat > app/src/main/AndroidManifest.xml <<'MF'
<manifest package="com.example.app" xmlns:android="http://schemas.android.com/apk/res/android">
  <application android:label="@string/app_name">
    <activity android:name=".MainActivity">
      <intent-filter>
        <action android:name="android.intent.action.MAIN"/>
        <category android:name="android.intent.category.LAUNCHER"/>
      </intent-filter>
    </activity>
  </application>
</manifest>
MF

cat > app/src/main/res/values/strings.xml <<'SV'
<resources>
  <string name="app_name">mobile_app</string>
</resources>
SV

cat > app/src/main/res/layout/activity_main.xml <<'LX'
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android" android:orientation="vertical" android:layout_width="match_parent" android:layout_height="match_parent">
  <TextView android:layout_width="wrap_content" android:layout_height="wrap_content" android:text="mobile_app placeholder" />
</LinearLayout>
LX

cat > app/src/main/java/com/example/app/MainActivity.java <<'MA'
package com.example.app;
import android.app.Activity;
import android.os.Bundle;
import android.widget.TextView;
public class MainActivity extends Activity {
  @Override protected void onCreate(Bundle s) { super.onCreate(s); TextView tv=new TextView(this); tv.setText("mobile_app"); setContentView(tv); }
}
MA

# create gradle wrapper reliably
GRADLE_VERSION=8.2.1
if [ -f "$WORKSPACE/gradlew" ]; then :; else
  if command -v gradle >/dev/null 2>&1; then
    (cd "$WORKSPACE" && gradle wrapper) || true
  else
    # fallback: write minimal wrapper properties referencing official distribution
    mkdir -p "$WORKSPACE/gradle/wrapper"
    cat > "$WORKSPACE/gradle/wrapper/gradle-wrapper.properties" <<WPR
distributionUrl=https\://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip
WPR
    # create a minimal gradlew that will run the wrapper jar via java -jar when present
    cat > "$WORKSPACE/gradlew" <<'GW'
#!/usr/bin/env bash
set -euo pipefail
DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
JAR="$DIR/gradle/wrapper/gradle-wrapper.jar"
if [ -f "$JAR" ]; then exec java -jar "$JAR" "$@"; else echo "gradle wrapper jar missing; please run 'gradle wrapper' or place gradle-wrapper.jar at gradle/wrapper/" >&2; exit 2; fi
GW
    chmod +x "$WORKSPACE/gradlew"
  fi
fi

# helper scripts for later pipeline steps
cat > "$WORKSPACE/build.sh" <<'BS'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
./gradlew assembleDebug --no-daemon --console=plain
BS
chmod +x "$WORKSPACE/build.sh"

cat > "$WORKSPACE/start.sh" <<'SS'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
APK=$(find ./app/build/outputs/apk -type f -name "*.apk" | head -n1 || true)
[ -n "$APK" ] && echo "APK:$APK" || echo "No APK built yet"
SS
chmod +x "$WORKSPACE/start.sh"

touch "$WORKSPACE/.scaffolded_by_setup"

# Print concise success message for CI logs
echo "scaffold: created minimal Android project at $WORKSPACE"
