#!/bin/bash -e

# This is a helper script for testing *manually* detox Android
# Prerequisites:
# 0. detox has detox-debug.aar (created by e.g "scripts/build.sh noframework android")
# 1. RN packager is running in detox/test/
# 2. An Android simulator is running

echo -e "\nStarting ws echo server"
node_modules/wsrelay/cmd.js 8099 &>/dev/null &
PROC_ID_WS=$!

echo -e "\nInstalling app apk"
cd android
./gradlew assembleDebug
adb install -r -g app/build/outputs/apk/app-debug.apk

echo -e "\nStarting instrumentation test"
detoxServer="ws://10.0.2.2:8099"
detoxSessionId="test"
./gradlew connectedAndroidTest -Pandroid.testInstrumentationRunnerArguments.detoxServer="${detoxServer}" -Pandroid.testInstrumentationRunnerArguments.detoxSessionId="${detoxSessionId}" 2>&1 &
PROC_ID_INST=$!
cd ..

echo -e "\nStart sending test commands"
echo -e "\nAvailable test commands\n{'type':'testInvoke1','params':{}}\n{'type':'testPush','params':{}}\n{'type':'testInvoke2','params':{}}\n{'type':'testInvokeNeg1','params':{}}\n"
echo -e "{'type':'reactNativeReload','params':{}}\n{'type':'cleanup','params':{}}\n{'type':'isReady','params':{}}"
node_modules/wscat/bin/wscat --connect ws://localhost:8099

echo -e "\nStopping ws echo server"
kill -5 "$PROC_ID_WS"

echo -e "\nStopping instrumentation test runner (if needed)"
kill -5 "$PROC_ID_INST"