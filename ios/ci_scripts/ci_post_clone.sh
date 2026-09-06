#!/bin/sh
# Fail this script if any command fails.
set -e

# The default execution directory of this script is the ci_scripts directory.
cd $CI_WORKSPACE/findix_app

export HOMEBREW_NO_AUTO_UPDATE=1

echo "==> Cloning Flutter"
git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter
export PATH="$PATH:$HOME/flutter/bin"

echo "==> Pre-caching Flutter"
flutter precache --ios

echo "==> Getting Flutter packages"
flutter pub get

echo "==> Installing CocoaPods"
HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods

echo "==> Pod install"
cd ios
pod install
