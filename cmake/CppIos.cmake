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

    if(NOT DEFINED WORKORDER_YANDEX_OAUTH_CLIENT_ID)
        set(WORKORDER_YANDEX_OAUTH_CLIENT_ID "d3e1a705454a448b841e617117fec451")
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

    set_target_properties(${target} PROPERTIES
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
        QT_IOS_PACKAGE_SOURCE_DIR "${_ios_pkg}"
        MACOSX_BUNDLE_GUI_IDENTIFIER "${WORKORDER_IOS_BUNDLE_ID}"
        QT_IOS_LAUNCH_SCREEN "${WORKORDER_ROOT}/cpp/ios/LaunchScreen.storyboard"
    )

    message(STATUS "iOS Yandex OAuth: bundle=${WORKORDER_IOS_BUNDLE_ID}, "
        "redirect=${WORKORDER_OAUTH_CALLBACK_SCHEME}://oauth-callback, "
        "loginSdkScheme=yx${WORKORDER_YANDEX_OAUTH_CLIENT_ID}")
    message(STATUS "iOS version: ${WORKORDER_VERSION} (${_ios_build_number})")
endfunction()
