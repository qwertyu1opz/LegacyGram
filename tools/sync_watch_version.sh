#!/bin/sh

if [ $# -ne 2 ]; then
    echo usage: $0 app-plist-file watch-plist-file
    exit 1
fi

plist="$1"
watchplist="$2"
dir="$(dirname "$plist")"

version=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$plist")

if [ -z "$version" ]; then
    echo "No version number in $plist"
    exit 2
fi

buildnum=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$plist")

if [ -z "$buildnum" ]; then
    echo "No build number in $plist"
    exit 2
fi

/usr/libexec/PlistBuddy -c "Set CFBundleShortVersionString $version" "$watchplist"
/usr/libexec/PlistBuddy -c "Set CFBundleVersion $buildnum" "$watchplist"
