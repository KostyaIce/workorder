# iOS packaging extras for WorkOrder (Qt 6): OAuth URL schemes for Yandex.

function(workorder_setup_ios_target target)
    if(NOT IOS)
        return()
    endif()

    if(NOT TARGET ${target})
        message(FATAL_ERROR "workorder_setup_ios_target: target '${target}' not found")
    endif()

    if(NOT DEFINED WORKORDER_YANDEX_OAUTH_CLIENT_ID)
        set(WORKORDER_YANDEX_OAUTH_CLIENT_ID "d3e1a705454a448b841e617117fec451")
    endif()

    if(NOT DEFINED WORKORDER_IOS_BUNDLE_ID)
        set(WORKORDER_IOS_BUNDLE_ID "com.workorder")
    endif()

    if(NOT DEFINED WORKORDER_OAUTH_CALLBACK_SCHEME)
        set(WORKORDER_OAUTH_CALLBACK_SCHEME "workorder")
    endif()

    set(_ios_src "${WORKORDER_ROOT}/cpp/ios/Info.plist.in")
    set(_ios_pkg "${CMAKE_CURRENT_BINARY_DIR}/ios_package")
    file(MAKE_DIRECTORY "${_ios_pkg}")

    configure_file("${_ios_src}" "${_ios_pkg}/Info.plist" @ONLY)

    set_target_properties(${target} PROPERTIES
        QT_IOS_PACKAGE_SOURCE_DIR "${_ios_pkg}"
        MACOSX_BUNDLE_GUI_IDENTIFIER "${WORKORDER_IOS_BUNDLE_ID}"
        QT_IOS_LAUNCH_SCREEN "${WORKORDER_ROOT}/cpp/ios/LaunchScreen.storyboard"
    )

    message(STATUS "iOS Yandex OAuth: bundle=${WORKORDER_IOS_BUNDLE_ID}, "
        "redirect=${WORKORDER_OAUTH_CALLBACK_SCHEME}://oauth-callback, "
        "loginSdkScheme=yx${WORKORDER_YANDEX_OAUTH_CLIENT_ID}")
endfunction()
