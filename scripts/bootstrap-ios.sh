#!/usr/bin/env bash
set -euo pipefail

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "xcodegen is required. Run: brew bundle"
  exit 1
fi

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root_dir"

xcodegen generate
plutil -lint Trellis/Info.plist
plutil -lint Trellis/Resources/PrivacyInfo.xcprivacy

xcodebuild \
  -project Trellis.xcodeproj \
  -scheme Trellis \
  -configuration Debug \
  -destination "generic/platform=iOS Simulator" \
  -derivedDataPath .build/DerivedData \
  CODE_SIGNING_ALLOWED=NO \
  build

