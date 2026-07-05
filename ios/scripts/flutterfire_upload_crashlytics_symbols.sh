#!/bin/bash
set -e

PATH="${PATH}:${FLUTTER_ROOT}/bin:${PUB_CACHE}/bin:${HOME}/.pub-cache/bin"

if [ "${CONFIGURATION}" = "Debug" ] || [ "${PLATFORM_NAME}" = "iphonesimulator" ]; then
  exit 0
fi

VENDORED_SCRIPT="${SRCROOT}/scripts/firebase_crashlytics_run.sh"
BUILD_IOS_SCRIPT="${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run"
PODS_SCRIPT="${PODS_ROOT}/FirebaseCrashlytics/run"

if [ -f "$VENDORED_SCRIPT" ]; then
  PATH_TO_CRASHLYTICS_UPLOAD_SCRIPT="$VENDORED_SCRIPT"
elif [ -f "$BUILD_IOS_SCRIPT" ]; then
  PATH_TO_CRASHLYTICS_UPLOAD_SCRIPT="$BUILD_IOS_SCRIPT"
elif [ -n "$PODS_ROOT" ] && [ -f "$PODS_SCRIPT" ]; then
  PATH_TO_CRASHLYTICS_UPLOAD_SCRIPT="$PODS_SCRIPT"
else
  DERIVED_DATA_PATH="$(echo "$BUILD_ROOT" | sed -E 's|(.*DerivedData/[^/]+).*|\1|')"
  PATH_TO_CRASHLYTICS_UPLOAD_SCRIPT="${DERIVED_DATA_PATH}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run"
fi

if [ ! -f "$PATH_TO_CRASHLYTICS_UPLOAD_SCRIPT" ]; then
  echo "error: Crashlytics upload script not found" >&2
  exit 1
fi

flutterfire upload-crashlytics-symbols \
  --upload-symbols-script-path="$PATH_TO_CRASHLYTICS_UPLOAD_SCRIPT" \
  --platform=ios \
  --apple-project-path="${SRCROOT}" \
  --env-platform-name="${PLATFORM_NAME}" \
  --env-configuration="${CONFIGURATION}" \
  --env-project-dir="${PROJECT_DIR}" \
  --env-built-products-dir="${BUILT_PRODUCTS_DIR}" \
  --env-dwarf-dsym-folder-path="${DWARF_DSYM_FOLDER_PATH}" \
  --env-dwarf-dsym-file-name="${DWARF_DSYM_FILE_NAME}" \
  --env-infoplist-path="${INFOPLIST_PATH}" \
  --default-config=default
