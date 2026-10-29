#!/bin/bash
# Adds the native Yandex Login SDK to a CMake-generated Xcode project.
set -euo pipefail

BUILD_DIR="${1:?Usage: ios_pods.sh BUILD_DIR}"
BUILD_DIR="$(cd "$BUILD_DIR" && pwd)"
PROJECT="$BUILD_DIR/WorkOrder.xcodeproj"
[ -d "$PROJECT" ] || { echo "ERROR: Xcode project not found: $PROJECT" >&2; exit 1; }
command -v pod >/dev/null || {
    echo "ERROR: CocoaPods is required for YandexLoginSDK. Install it with: sudo gem install cocoapods" >&2
    exit 1
}

PODFILE="$BUILD_DIR/Podfile"
cat > "$PODFILE" <<'EOF'
platform :ios, '13.0'
project 'WorkOrder.xcodeproj'

target 'WorkOrder' do
  use_frameworks!
  pod 'YandexLoginSDK', '~> 3.2'
end

# CMake builds the app in its own CONFIGURATION_BUILD_DIR, not in the default
# DerivedData products folder used by CocoaPods. Build the pods into the same
# folder so the CocoaPods embed script can find YandexLoginSDK.framework.
post_install do |installer|
  build_dir = ENV.fetch('WORKORDER_IOS_BUILD_DIR', File.expand_path(__dir__))
  products = File.join(build_dir, '$(CONFIGURATION)$(EFFECTIVE_PLATFORM_NAME)')

  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['CONFIGURATION_BUILD_DIR'] = products
      # The app target owns signing. Signed pod frameworks otherwise inherit
      # command-line bundle IDs and provisioning profiles from xcodebuild.
      config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
      config.build_settings['CODE_SIGNING_REQUIRED'] = 'NO'
      config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = "org.cocoapods.#{target.name}"
    end
  end

  installer.aggregate_targets.each do |aggregate|
    next unless aggregate.user_project
    aggregate.user_project.native_targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['FRAMEWORK_SEARCH_PATHS'] = "$(inherited) #{products}"
        config.build_settings['LIBRARY_SEARCH_PATHS'] = "$(inherited) #{products}"
      end
    end
  end
end
EOF

( cd "$BUILD_DIR" && WORKORDER_IOS_BUILD_DIR="$BUILD_DIR" pod install )
[ -d "$BUILD_DIR/WorkOrder.xcworkspace" ] || {
    echo "ERROR: CocoaPods did not create WorkOrder.xcworkspace" >&2
    exit 1
}
echo "YandexLoginSDK linked through $BUILD_DIR/WorkOrder.xcworkspace"
