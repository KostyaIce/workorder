include("${CMAKE_CURRENT_LIST_DIR}/WorkOrderPython.cmake")

function(workorder_add_python_run_target target_name app_type)
    if(APPLE)
        set(_bundle "${CMAKE_BINARY_DIR}/WorkOrder-${app_type}.app")
        set(_launcher "${_bundle}/Contents/MacOS/WorkOrder-${app_type}")

        add_custom_target("app-bundle-${app_type}"
            COMMAND chmod +x "${WORKORDER_ROOT}/scripts/macos/create_app_bundle.sh"
            COMMAND "${WORKORDER_ROOT}/scripts/macos/create_app_bundle.sh"
                "${WORKORDER_ROOT}"
                "${CMAKE_BINARY_DIR}"
                "${app_type}"
                "${WORKORDER_PYTHON}"
                "WorkOrder-${app_type}"
            DEPENDS build
            COMMENT "Create WorkOrder-${app_type}.app bundle for macOS"
            VERBATIM
        )

        add_custom_target(${target_name}
            COMMAND "${_launcher}"
            DEPENDS "app-bundle-${app_type}"
            COMMENT "Run WorkOrder Python (${app_type}) via WorkOrder-${app_type}.app"
            VERBATIM
        )
    else()
        add_custom_target(${target_name}
            COMMAND chmod +x "${WORKORDER_ROOT}/scripts/run_workorder.sh"
            COMMAND ${CMAKE_COMMAND} -E env
                "WORKORDER_BUILD_DIR=${CMAKE_BINARY_DIR}"
                "${WORKORDER_ROOT}/scripts/run_workorder.sh"
                ${app_type}
                "${CMAKE_BINARY_DIR}"
            WORKING_DIRECTORY "${WORKORDER_ROOT}"
            DEPENDS build
            COMMENT "Run WorkOrder Python (${app_type})"
            VERBATIM
        )
    endif()

    set_target_properties(${target_name} PROPERTIES
        FOLDER "qtc_runnable"
        WORKORDER_APP_TYPE "${app_type}"
    )
endfunction()
