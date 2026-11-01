#!/usr/bin/env bash
#
# Build, sign, notarize and package Wedge for release.
#
#   WEDGE_TEAM_ID=ABCDE12345 WEDGE_NOTARY_PROFILE=wedge-notary scripts/release.sh 1.0.0
#
# Environment:
#   WEDGE_TEAM_ID         Apple Developer team ID used for Developer ID signing.
#   WEDGE_NOTARY_PROFILE  notarytool keychain profile name, created once with
#                         `xcrun notarytool store-credentials`.
#
# Output goes to build/release/<version>/, ending with Wedge-<version>.zip.
# The script stops at the first failure.

set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage: scripts/release.sh <version>

  <version>  semantic version such as 1.0.0 (digits and dots only)

Required environment variables:
  WEDGE_TEAM_ID         Apple Developer team ID
  WEDGE_NOTARY_PROFILE  notarytool keychain profile name
USAGE
}

fail() {
  echo "error: $*" >&2
  exit 1
}

if [[ $# -ne 1 ]]; then
  usage
  exit 2
fi

version="$1"
if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "error: invalid version '$version'" >&2
  usage
  exit 2
fi

[[ -n "${WEDGE_TEAM_ID:-}" ]] || fail "WEDGE_TEAM_ID is not set (your Apple Developer team ID)."
[[ -n "${WEDGE_NOTARY_PROFILE:-}" ]] || fail "WEDGE_NOTARY_PROFILE is not set (your notarytool keychain profile name)."
[[ "$(uname)" == "Darwin" ]] || fail "releases must be built on macOS."

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
out_dir="$repo_root/build/release/$version"
archive_path="$out_dir/Wedge.xcarchive"
export_dir="$out_dir/export"
options_plist="$out_dir/ExportOptions.plist"
submit_zip="$out_dir/Wedge-$version-notarize.zip"
notary_json="$out_dir/notary-result.json"
final_zip="$out_dir/Wedge-$version.zip"

rm -rf "$out_dir"
mkdir -p "$out_dir"
cd "$repo_root"

cat >"$options_plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>developer-id</string>
  <key>teamID</key>
  <string>$WEDGE_TEAM_ID</string>
  <key>signingStyle</key>
  <string>automatic</string>
</dict>
</plist>
PLIST

echo "==> 1/6 Archiving Wedge $version (Release)"
xcodebuild archive \
  -project wedge.xcodeproj \
  -scheme wedge \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -archivePath "$archive_path" \
  DEVELOPMENT_TEAM="$WEDGE_TEAM_ID"

echo "==> 2/6 Exporting with Developer ID signing"
xcodebuild -exportArchive \
  -archivePath "$archive_path" \
  -exportOptionsPlist "$options_plist" \
  -exportPath "$export_dir"

shopt -s nullglob
apps=("$export_dir"/*.app)
shopt -u nullglob
[[ ${#apps[@]} -eq 1 ]] || fail "expected exactly one .app in $export_dir, found ${#apps[@]}."
app_path="${apps[0]}"

echo "==> 3/6 Zipping for notarization"
ditto -c -k --keepParent "$app_path" "$submit_zip"

echo "==> 4/6 Notarizing (waits for Apple)"
xcrun notarytool submit "$submit_zip" \
  --keychain-profile "$WEDGE_NOTARY_PROFILE" \
  --wait \
  --output-format json >"$notary_json" || {
  cat "$notary_json" >&2
  fail "notarytool submit failed."
}
cat "$notary_json"
status="$(plutil -extract status raw -o - "$notary_json")"
if [[ "$status" != "Accepted" ]]; then
  submission_id="$(plutil -extract id raw -o - "$notary_json" || true)"
  fail "notarization finished with status '$status'. Fetch the log with: xcrun notarytool log $submission_id --keychain-profile \"\$WEDGE_NOTARY_PROFILE\""
fi

echo "==> 5/6 Stapling and re-zipping"
xcrun stapler staple "$app_path"
rm -f "$final_zip"
ditto -c -k --keepParent "$app_path" "$final_zip"
rm -f "$submit_zip"

echo "==> 6/6 SHA-256"
shasum -a 256 "$final_zip" | tee "$final_zip.sha256"

echo "Done: $final_zip"
