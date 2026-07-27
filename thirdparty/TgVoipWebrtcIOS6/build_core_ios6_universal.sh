#!/bin/sh
set -e

ROOT="$(cd "$(dirname "$0")" && pwd)"
SIM_OUT="${1:-/private/tmp/tgcalls_ios6_core_i386}"
DEV_OUT="${2:-/private/tmp/tgcalls_ios6_core_armv7}"
FAT_OUT="${3:-$ROOT/lib/libTgVoipWebrtcIOS6Core.a}"

ARCH=i386 SDK=iphonesimulator "$ROOT/build_core_ios6.sh" "$SIM_OUT"
ARCH=armv7 SDK=iphoneos "$ROOT/build_core_ios6.sh" "$DEV_OUT"

xcrun lipo -create \
  "$SIM_OUT/libTgVoipWebrtcIOS6Core.a" \
  "$DEV_OUT/libTgVoipWebrtcIOS6Core.a" \
  -output "$FAT_OUT"

xcrun lipo -info "$FAT_OUT"
