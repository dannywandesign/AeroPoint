#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${AEROPOINT_VERSION:-0.1}"
RID="${AEROPOINT_WINDOWS_RID:-win-x64}"
PUBLISH_DIR="$ROOT_DIR/dist/windows/$RID"
ZIP_PATH="$ROOT_DIR/dist/AeroPointAgent-windows-$RID-$VERSION.zip"

rm -rf "$PUBLISH_DIR" "$ZIP_PATH"
mkdir -p "$PUBLISH_DIR" "$ROOT_DIR/dist"

echo "Publishing Windows agent for $RID..."
dotnet publish "$ROOT_DIR/windows/AeroPointAgent.csproj" \
  -c Release \
  -r "$RID" \
  --self-contained true \
  -p:EnableWindowsTargeting=true \
  -p:PublishSingleFile=true \
  -p:IncludeNativeLibrariesForSelfExtract=true \
  -p:DebugType=None \
  -p:DebugSymbols=false \
  -o "$PUBLISH_DIR"

if command -v powershell.exe >/dev/null 2>&1; then
  echo "Windows signing is not automated by this script. Sign AeroPointAgent.exe with signtool on Windows if you have a code signing certificate."
fi

cd "$PUBLISH_DIR"
zip -qr "$ZIP_PATH" .
echo "Created $ZIP_PATH"
