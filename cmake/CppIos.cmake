# iOS packaging extras for WorkOrder (Qt 6): OAuth URL schemes for Yandex.

function(workorder_setup_ios_target target)
    if(NOT IOS)
        return()
    endif()

    if(NOT TARGET ${target})
        message(FATAL_ERROR "workorder_setup_ios_target: target '${target}' not found")
    endif()

    # iOS: 1.0.27 -> marketing version 1.0.27, build number 1000027.
    if(VERSION_MINOR GREATER_EQUAL 1000 OR VERSION_PATCH GREATER_EQUAL 1000)
        message(FATAL_ERROR "iOS version minor and patch must be below 1000")
    endif()
    math(EXPR _ios_build_number
        "${VERSION_MAJOR} * 1000000 + ${VERSION_MINOR} * 1000 + ${VERSION_PATCH}")

    if(NOT WORKORDER_YANDEX_OAUTH_CLIENT_ID)
        message(FATAL_ERROR "WORKORDER_YANDEX_OAUTH_CLIENT_ID is not set. Define it in cpp/CMakeLists.txt")
    endif()

    if(NOT DEFINED WORKORDER_IOS_BUNDLE_ID)
        set(WORKORDER_IOS_BUNDLE_ID "com.workorder")
    endif()

    if(NOT DEFINED WORKORDER_IOS_TEAM_ID)
        set(WORKORDER_IOS_TEAM_ID "74FAM6RATH")
    endif()

    if(NOT DEFINED WORKORDER_OAUTH_CALLBACK_SCHEME)
        set(WORKORDER_OAUTH_CALLBACK_SCHEME "workorder")
    endif()

    set(_ios_src "${WORKORDER_ROOT}/cpp/ios/Info.plist.in")
    set(_ios_pkg "${CMAKE_CURRENT_BINARY_DIR}/ios_package")
    file(MAKE_DIRECTORY "${_ios_pkg}")

    configure_file("${_ios_src}" "${_ios_pkg}/Info.plist" @ONLY)

    # Native Yandex Login SDK bridge. The SDK itself is linked through
    # CocoaPods by prod_build/build_ios*.sh (YandexLoginSDK ~> 3.2).
    enable_language(Swift)
    set(CMAKE_Swift_LANGUAGE_VERSION 5.0)
    set(_ios_swift_headers "${CMAKE_CURRENT_BINARY_DIR}/ios_swift")
    file(MAKE_DIRECTORY "${_ios_swift_headers}")
    target_sources(${target} PRIVATE
        "${WORKORDER_ROOT}/cpp/ios/YandexAuth.swift"
        "${WORKORDER_ROOT}/cpp/ios/YandexAuth.mm"
    )
    target_include_directories(${target} PRIVATE "${_ios_swift_headers}")

    set(_ios_icons "${WORKORDER_ROOT}/cpp/ios/Assets.xcassets")
    if(EXISTS "${_ios_icons}")
        # Xcode must compile the asset catalog with actool. Copying it into
        # QT_IOS_PACKAGE_SOURCE_DIR alone does not add it to Resources.
        target_sources(${target} PRIVATE "${_ios_icons}")
        set_source_files_properties("${_ios_icons}" PROPERTIES
            MACOSX_PACKAGE_LOCATION Resources
        )
    else()
        message(FATAL_ERROR "iOS app icon catalog missing: ${_ios_icons}")
    endif()

    # Qt 6.8 adds a bare -no_warn_duplicate_libraries flag, which Xcode 26
    # clang rejects. The warning suppression is not needed for the app target.
    set_property(TARGET ${target} PROPERTY QT_NO_DISABLE_WARN_DUPLICATE_LIBRARIES ON)

    set_target_properties(${target} PROPERTIES
        MACOSX_BUNDLE_INFO_PLIST "${_ios_src}"
        MACOSX_BUNDLE_BUNDLE_VERSION "${_ios_build_number}"
        MACOSX_BUNDLE_SHORT_VERSION_STRING "${WORKORDER_VERSION}"
        XCODE_ATTRIBUTE_CURRENT_PROJECT_VERSION "${_ios_build_number}"
        XCODE_ATTRIBUTE_MARKETING_VERSION "${WORKORDER_VERSION}"
        XCODE_ATTRIBUTE_ASSETCATALOG_COMPILER_APPICON_NAME "AppIcon"
        XCODE_ATTRIBUTE_TARGETED_DEVICE_FAMILY "1"
        XCODE_ATTRIBUTE_SUPPORTS_MACCATALYST "NO"
        XCODE_ATTRIBUTE_CODE_SIGN_STYLE "Automatic"
        XCODE_ATTRIBUTE_DEVELOPMENT_TEAM "${WORKORDER_IOS_TEAM_ID}"
        XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER "${WORKORDER_IOS_BUNDLE_ID}"
        # CocoaPods builds Pods_WorkOrder.framework in its own products dir,
        # not in the CMake CONFIGURATION_BUILD_DIR.
        XCODE_ATTRIBUTE_FRAMEWORK_SEARCH_PATHS "$(inherited) $(PODS_CONFIGURATION_BUILD_DIR)"
        Swift_VERSION "5.0"
        XCODE_ATTRIBUTE_SWIFT_VERSION "5.0"
        XCODE_ATTRIBUTE_SWIFT_OBJC_INTERFACE_HEADER_NAME "WorkOrder-Swift.h"
        XCODE_ATTRIBUTE_SWIFT_OBJC_INTERFACE_HEADER_DIR "${_ios_swift_headers}"
        QT_IOS_PACKAGE_SOURCE_DIR "${_ios_pkg}"
        MACOSX_BUNDLE_GUI_IDENTIFIER "${WORKORDER_IOS_BUNDLE_ID}"
        QT_IOS_LAUNCH_SCREEN "${WORKORDER_ROOT}/cpp/ios/LaunchScreen.storyboard"
    )

    message(STATUS "iOS Yandex Login SDK: bundle=${WORKORDER_IOS_BUNDLE_ID}, "
        "scheme=yx${WORKORDER_YANDEX_OAUTH_CLIENT_ID}")
    message(STATUS "iOS version: ${WORKORDER_VERSION} (${_ios_build_number})")
endfunction()
