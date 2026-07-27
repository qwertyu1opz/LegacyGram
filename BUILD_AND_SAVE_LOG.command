#!/bin/bash

set -o pipefail

project_dir="$(cd "$(dirname "$0")" && pwd)"
log_file="$project_dir/LegacyGram_xcodebuild.log"

cd "$project_dir" || exit 1

{
    echo "LegacyGram build diagnostics"
    date
    echo
    sw_vers
    echo
    xcode-select -p
    xcodebuild -version
    echo
    xcodebuild -workspace Telegram.xcworkspace -list
    echo
    xcodebuild \
        -workspace Telegram.xcworkspace \
        -scheme Telegraph \
        -configuration Debug \
        -sdk iphoneos \
        CODE_SIGNING_REQUIRED=NO \
        CODE_SIGN_IDENTITY="" \
        build
} 2>&1 | tee "$log_file"

status=${PIPESTATUS[0]}
echo
echo "Build exit code: $status"
echo "Log saved to: $log_file"
echo
read -r -p "Press Return to close..."
exit "$status"
