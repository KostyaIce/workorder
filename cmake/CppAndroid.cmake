# Android packaging for WorkOrder C++ (Qt 6 / androiddeployqt).

function(workorder_setup_android_target target)
    if(NOT ANDROID)
        return()
    endif()

    if(NOT TARGET ${target})
        message(FATAL_ERROR "workorder_setup_android_target: target '${target}' not found")
    endif()

    set(_android_dir "${WORKORDER_ROOT}/cpp/android")

    set_target_properties(${target} PROPERTIES
        QT_ANDROID_PACKAGE_SOURCE_DIR "${_android_dir}"
        QT_ANDROID_APP_NAME "WorkOrder"
        QT_ANDROID_APPLICATION_ARGUMENTS "--type mobile"
    )

    if(COMMAND qt_add_android_permission)
        qt_add_android_permission(${target}
            NAME android.permission.READ_EXTERNAL_STORAGE
        )
        qt_add_android_permission(${target}
            NAME android.permission.WRITE_EXTERNAL_STORAGE
        )
    endif()

    message(STATUS "Android target configured: compact mobile UI, package com.workorder")
endfunction()

function(workorder_add_android_run_target target_name)
    if(NOT ANDROID)
        return()
    endif()

    if(NOT TARGET WorkOrder)
        return()
    endif()

    add_custom_target(${target_name}
        COMMAND ${CMAKE_COMMAND} --build ${CMAKE_BINARY_DIR} --target WorkOrder_make_apk
        DEPENDS WorkOrder
        COMMENT "Build WorkOrder Android APK (mobile UI)"
        VERBATIM
    )
    set_target_properties(${target_name} PROPERTIES
        FOLDER "qtc_runnable"
        WORKORDER_APP_TYPE "mobile"
    )
endfunction()
