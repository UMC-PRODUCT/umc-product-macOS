#!/bin/bash
#  Created by euijjang97 on 11/25/26.
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
products="$root/UMCDesk/Build/Products/Release"
output="${1:?Pass an unused destination ending in .app}"
[[ "$output" == *.app && ! -e "$output" ]] || exit 2
stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT
bundle="$stage/Dock.app/Contents"
mkdir -p "$bundle/MacOS" "$bundle/Resources"
for resource in Home_HomePresentation CoreDesignSystem_CoreDesignSystem UMCFoundation_UMCFoundation; do
    ditto "$products/$resource.bundle" "$bundle/Resources/$resource.bundle"
done
xcrun swiftc -parse-as-library -O -target arm64-apple-macos26.0 \
    -F "$products" -framework HomePresentation -framework HomeDomain \
    -framework CoreUIComponents -framework CoreDesignSystem -framework CoreDomain -framework UMCFoundation \
    "$root/tools/qa/DockPerformanceHost.swift" -o "$bundle/MacOS/Dock"
plutil -create xml1 "$bundle/Info.plist"
plutil -insert CFBundleIdentifier -string org.umc.desk.dock-qa "$bundle/Info.plist"
plutil -insert CFBundleName -string Dock "$bundle/Info.plist"
plutil -insert CFBundleExecutable -string Dock "$bundle/Info.plist"
plutil -insert CFBundlePackageType -string APPL "$bundle/Info.plist"
plutil -insert NSHighResolutionCapable -bool YES "$bundle/Info.plist"
codesign --force --deep --sign - "$stage/Dock.app"
ditto "$stage/Dock.app" "$output"
