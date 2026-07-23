macro(workorder_find_qt6_cpp)
    workorder_apply_qt_prefix_path()
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
