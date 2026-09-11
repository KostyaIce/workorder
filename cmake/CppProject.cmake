# The macOS 26 SDK dropped the legacy AGL framework, while the framework stub is
# still present in the running system. Qt 6.8 FindWrapOpenGL.cmake finds it in
# /System/Library/Frameworks and adds "-framework AGL", which the linker cannot
# resolve inside the SDK. Qt itself does not use AGL, so point the cache entry to
# OpenGL.framework, which is already part of the link line.
function(workorder_fix_macos_agl_framework)
    if(NOT APPLE OR IOS OR ANDROID)
        return()
    endif()

    set(_sysroot "${CMAKE_OSX_SYSROOT}")
    if(NOT IS_DIRECTORY "${_sysroot}")
        return()
    endif()

    if(EXISTS "${_sysroot}/System/Library/Frameworks/AGL.framework")
        return()
    endif()

    set(_opengl_framework "${_sysroot}/System/Library/Frameworks/OpenGL.framework")
    if(NOT EXISTS "${_opengl_framework}")
        return()
    endif()

    set(WrapOpenGL_AGL "${_opengl_framework}" CACHE FILEPATH "Path to a library." FORCE)
    message(STATUS "macOS SDK without AGL framework: WrapOpenGL_AGL redirected to OpenGL.framework")
endfunction()

macro(workorder_find_qt6_cpp)
    workorder_apply_qt_prefix_path()
    workorder_fix_macos_agl_framework()
    find_package(Qt6 6.5 REQUIRED COMPONENTS Core Sql Gui Network Qml Quick)
    if(NOT ANDROID)
        find_package(Qt6 6.5 QUIET COMPONENTS Pdf)
    endif()
    message(STATUS "Qt6 ${Qt6_VERSION} found at ${Qt6_DIR}")
    if(ANDROID)
        message(STATUS "Qt host tools: ${QT_HOST_PATH}")
    endif()
    if(Qt6Pdf_FOUND)
        message(STATUS "Qt6 Pdf module found (QML preview enabled)")
    elseif(NOT ANDROID)
        message(STATUS "Qt6 Pdf module not found (PDF preview falls back to external viewer)")
    endif()
endmacro()

function(workorder_add_cpp_run_target target_name app_type)
    if(NOT TARGET WorkOrder)
        return()
    endif()

    add_custom_target(${target_name}
        COMMAND "$<TARGET_FILE:WorkOrder>" --type ${app_type}
        DEPENDS WorkOrder
        WORKING_DIRECTORY "${WORKORDER_ROOT}"
        COMMENT "Run WorkOrder C++ (${app_type})"
        VERBATIM
    )

    set_target_properties(${target_name} PROPERTIES
        FOLDER "qtc_runnable"
        WORKORDER_APP_TYPE "${app_type}"
    )
endfunction()
