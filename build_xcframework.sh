#!/usr/bin/env bash
set -euo pipefail

PROJECT="MySSOSDK.xcodeproj"
SCHEME="MySSOSDK"
CONFIGURATION="Release"
OUTPUT_DIR="build"
IOS_ARCHIVE_PATH="$OUTPUT_DIR/MySSOSDK-iOS.xcarchive"
SIM_ARCHIVE_PATH="$OUTPUT_DIR/MySSOSDK-Sim.xcarchive"
XCFRAMEWORK_PATH="$OUTPUT_DIR/MySSOSDK.xcframework"
ZIP_PATH="$OUTPUT_DIR/MySSOSDK.xcframework.zip"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "Cleaning old artifacts..."
rm -rf "$IOS_ARCHIVE_PATH" "$SIM_ARCHIVE_PATH" "$XCFRAMEWORK_PATH" "$ZIP_PATH"
mkdir -p "$OUTPUT_DIR"

echo "Archiving for iOS devices..."
xcodebuild archive \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination "generic/platform=iOS" \
  -archivePath "$IOS_ARCHIVE_PATH" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES

echo "Archiving for iOS Simulator..."
xcodebuild archive \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination "generic/platform=iOS Simulator" \
  -archivePath "$SIM_ARCHIVE_PATH" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES

echo "Creating XCFramework..."
xcodebuild -create-xcframework \
  -framework "$IOS_ARCHIVE_PATH/Products/Library/Frameworks/MySSOSDK.framework" \
  -framework "$SIM_ARCHIVE_PATH/Products/Library/Frameworks/MySSOSDK.framework" \
  -output "$XCFRAMEWORK_PATH"

echo "Zipping XCFramework..."
/usr/bin/zip -r -q "$ZIP_PATH" "$XCFRAMEWORK_PATH"

echo "Done."
echo "XCFramework: $XCFRAMEWORK_PATH"
echo "Zip file:    $ZIP_PATH"
