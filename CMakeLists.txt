cmake_minimum_required(VERSION 3.16)

project(WorkOrder
    VERSION 1.0.0
    DESCRIPTION "Invoice and services management application"
    LANGUAGES C CXX
)

include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/QtCreatorIntegration.cmake")

set(Type "desktop" CACHE STRING "Application UI type: desktop or mobile")
set_property(CACHE Type PROPERTY STRINGS desktop mobile)

if(NOT Type MATCHES "^(desktop|mobile)$")
    message(FATAL_ERROR "Type must be 'desktop' or 'mobile', got: '${Type}'")
endif()

find_package(Python3 REQUIRED COMPONENTS Interpreter)

if(EXISTS "${CMAKE_SOURCE_DIR}/.venv/bin/python")
    set(WORKORDER_PYTHON "${CMAKE_SOURCE_DIR}/.venv/bin/python")
else()
    set(WORKORDER_PYTHON "${Python3_EXECUTABLE}")
endif()

workorder_find_qt6()

if(Qt6_FOUND)
    message(STATUS "Qt6 ${Qt6_VERSION} found at ${Qt6_DIR}")
    message(STATUS "QML language support enabled for Qt Creator")
else()
    message(STATUS "Runtime uses PyQt6; install: pip install -r requirements.txt")
endif()

set(QML_DIR "${CMAKE_SOURCE_DIR}/resources/qml/${Type}")

set(APP_ICON_SOURCES
    resources/icons/appIcons/icon_macos.icns
    resources/icons/appIcons/icon_win32.ico
    resources/icons/appIcons/icon_linux.png
)

set(PYTHON_SOURCES
    src/main.py
    src/app_paths.py
    src/macos_icon.py
    src/backend/__init__.py
    src/backend/invoice_backend.py
    src/backend/database_backend.py
    src/backend/settings_backend.py
    src/backend/report_backend.py
    src/backend/report_options_backend.py
    src/models/__init__.py
    src/utils/__init__.py
    src/utils/db_storage.py
    src/utils/report_builder.py
    src/utils/pdf_report_builder.py
    src/utils/services_pdf_builder.py
    src/ui/__init__.py
)

file(GLOB QML_SOURCES "${QML_DIR}/*.qml")

set(ALL_SOURCES
    ${PYTHON_SOURCES}
    ${QML_SOURCES}
    ${APP_ICON_SOURCES}
    requirements.txt
    README.md
)

workorder_setup_qml_import_path("${QML_DIR}")

# Default build target for Qt Creator (no C++ link step in this project)
add_custom_target(build ALL
    COMMAND ${CMAKE_COMMAND} -E echo "WorkOrder ${Type} configured. Build target 'run' to start the app."
    DEPENDS ${ALL_SOURCES}
    COMMENT "Prepare WorkOrder (${Type})"
    VERBATIM
)

# Compile-time application type for Python entry point
file(GENERATE OUTPUT "${CMAKE_BINARY_DIR}/workorder_config.py"
    CONTENT "APP_TYPE = '${Type}'\n"
)

configure_file(
    "${CMAKE_SOURCE_DIR}/cmake/config.py.in"
    "${CMAKE_BINARY_DIR}/workorder_build_info.py"
    @ONLY
)

if(APPLE)
    file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/macos")
    configure_file(
        "${CMAKE_SOURCE_DIR}/cmake/macos/Info.plist.in"
        "${CMAKE_BINARY_DIR}/macos/Info.plist"
        @ONLY
    )

    set(WORKORDER_APP_BUNDLE "${CMAKE_BINARY_DIR}/WorkOrder.app")
    set(WORKORDER_APP_LAUNCHER "${WORKORDER_APP_BUNDLE}/Contents/MacOS/WorkOrder")

    add_custom_target(app-bundle
        COMMAND chmod +x "${CMAKE_SOURCE_DIR}/scripts/macos/create_app_bundle.sh"
        COMMAND "${CMAKE_SOURCE_DIR}/scripts/macos/create_app_bundle.sh"
            "${CMAKE_SOURCE_DIR}"
            "${CMAKE_BINARY_DIR}"
            "${Type}"
            "${WORKORDER_PYTHON}"
        DEPENDS ${ALL_SOURCES} "${CMAKE_BINARY_DIR}/macos/Info.plist"
        COMMENT "Create WorkOrder.app bundle for macOS"
        VERBATIM
    )
endif()

if(APPLE)
    add_custom_target(run
        COMMAND "${WORKORDER_APP_LAUNCHER}"
        DEPENDS app-bundle
        COMMENT "Run WorkOrder (${Type}) via WorkOrder.app"
        VERBATIM
    )
else()
    add_custom_target(run
        COMMAND ${CMAKE_COMMAND} -E env
            "WORKORDER_BUILD_DIR=${CMAKE_BINARY_DIR}"
            "PYTHONPATH=${CMAKE_BINARY_DIR}:${CMAKE_SOURCE_DIR}/src"
            "QML_IMPORT_PATH=${CMAKE_SOURCE_DIR}/resources/qml:${QML_DIR}"
            ${WORKORDER_PYTHON}
            "${CMAKE_SOURCE_DIR}/src/main.py"
            --type ${Type}
        WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
        DEPENDS ${ALL_SOURCES}
        COMMENT "Run WorkOrder (${Type})"
        VERBATIM
    )
endif()

add_custom_target(install-deps
    COMMAND ${Python3_EXECUTABLE} -m pip install -r "${CMAKE_SOURCE_DIR}/requirements.txt"
    WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
    COMMENT "Install Python dependencies"
    VERBATIM
)

add_custom_target(test
    COMMAND ${WORKORDER_PYTHON} -m unittest discover -s tests -v
    WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
    COMMENT "Run unit tests"
    VERBATIM
)

message(STATUS "WorkOrder configured: Type=${Type}")
message(STATUS "Python: ${WORKORDER_PYTHON}")
message(STATUS "QML directory: ${QML_DIR}")
message(STATUS "Run: cmake --build ${CMAKE_BINARY_DIR} --target run")
