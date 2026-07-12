#!/bin/sh
set -e

if [ "${CONFIGURATION}" = "Debug" ] || [ "${PLATFORM_NAME}" = "iphonesimulator" ]; then
  exit 0
fi

DERIVED_SCRIPT="${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run"
FLUTTER_SCRIPT="${SRCROOT}/../build/ios/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run"
PODS_SCRIPT="${PODS_ROOT}/FirebaseCrashlytics/run"
VENDORED_SCRIPT="${SRCROOT}/scripts/firebase_crashlytics_run.sh"

if [ -f "$VENDORED_SCRIPT" ]; then
  UPLOAD_SCRIPT="$VENDORED_SCRIPT"
elif [ -f "$DERIVED_SCRIPT" ]; then
  UPLOAD_SCRIPT="$DERIVED_SCRIPT"
elif [ -f "$FLUTTER_SCRIPT" ]; then
  UPLOAD_SCRIPT="$FLUTTER_SCRIPT"
elif [ -n "$PODS_ROOT" ] && [ -f "$PODS_SCRIPT" ]; then
  UPLOAD_SCRIPT="$PODS_SCRIPT"
else
  echo "error: Crashlytics upload script not found" >&2
  exit 1
fi

"$UPLOAD_SCRIPT"
