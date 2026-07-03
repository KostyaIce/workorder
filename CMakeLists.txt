cmake_minimum_required(VERSION 3.16)

project(WorkOrder
    VERSION 1.0.0
    DESCRIPTION "Invoice and services management application"
    LANGUAGES C CXX
)

include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/QtCreatorIntegration.cmake")

set(Type "desktop" CACHE STRING "Default UI type for generic run target: desktop or mobile")
set_property(CACHE Type PROPERTY STRINGS desktop mobile)

if(NOT Type MATCHES "^(desktop|mobile)$")
    message(FATAL_ERROR "Type must be 'desktop' or 'mobile', got: '${Type}'")
endif()

find_package(Python3 REQUIRED COMPONENTS Interpreter)

workorder_resolve_python(WORKORDER_PYTHON WORKORDER_PYQT6_FOUND)
if(WORKORDER_PYQT6_FOUND)
    message(STATUS "Python with PyQt6: ${WORKORDER_PYTHON}")
else()
    message(WARNING
        "PyQt6 is not installed for any Python interpreter.\n"
        "  Qt Creator: build target 'install-deps', then Run CMake.\n"
        "  Shell: python3 -m venv .venv && .venv/bin/pip install -r requirements.txt"
    )
endif()

workorder_find_qt6()

if(Qt6_FOUND)
    message(STATUS "Qt6 ${Qt6_VERSION} found at ${Qt6_DIR}")
    message(STATUS "QML language support enabled for Qt Creator")
else()
    message(STATUS "Runtime uses PyQt6; install: pip install -r requirements.txt")
endif()

set(QML_DIR "${CMAKE_SOURCE_DIR}/resources/qml/${Type}")

workorder_collect_project_sources(
    ALL_SOURCES
    DESKTOP_SOURCES
    MOBILE_SOURCES
    COMMON_SOURCES
)

file(GLOB_RECURSE PYTHON_SOURCES CONFIGURE_DEPENDS "${CMAKE_SOURCE_DIR}/src/*.py")
workorder_filter_project_files(PYTHON_SOURCES)
file(GLOB_RECURSE TEST_SOURCES CONFIGURE_DEPENDS "${CMAKE_SOURCE_DIR}/tests/*.py")
workorder_filter_project_files(TEST_SOURCES)

workorder_setup_qml_import_path("${QML_DIR}")

workorder_apply_source_groups(
    DESKTOP ${DESKTOP_SOURCES}
    MOBILE ${MOBILE_SOURCES}
    COMMON ${COMMON_SOURCES}
    PYTHON ${PYTHON_SOURCES}
    TESTS ${TEST_SOURCES}
)

# Default build target for Qt Creator (no C++ link step in this project)
add_custom_target(build ALL
    COMMAND ${CMAKE_COMMAND} -E echo "WorkOrder configured. Run targets: run-desktop, run-mobile."
    SOURCES ${ALL_SOURCES}
    COMMENT "Prepare WorkOrder"
    VERBATIM
)
set_target_properties(build PROPERTIES FOLDER "Project/Build")
workorder_register_ide_sources(build FILES ${ALL_SOURCES})

add_custom_target(desktop-ui SOURCES ${DESKTOP_SOURCES})
add_custom_target(mobile-ui SOURCES ${MOBILE_SOURCES})
add_custom_target(common-ui SOURCES ${COMMON_SOURCES})

add_library(workorder_ide STATIC EXCLUDE_FROM_ALL
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/ide_stub.cpp"
)
target_sources(workorder_ide PRIVATE ${ALL_SOURCES})
set_source_files_properties(${ALL_SOURCES} PROPERTIES HEADER_FILE_ONLY TRUE)
set_target_properties(workorder_ide PROPERTIES
    AUTOMOC OFF
    AUTORCC OFF
    AUTOUIC OFF
)

# Compile-time application type for Python entry point (used when Type cache is set)
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

    add_custom_target(app-bundle
        COMMAND chmod +x "${CMAKE_SOURCE_DIR}/scripts/macos/create_app_bundle.sh"
        COMMAND "${CMAKE_SOURCE_DIR}/scripts/macos/create_app_bundle.sh"
            "${CMAKE_SOURCE_DIR}"
            "${CMAKE_BINARY_DIR}"
            "${Type}"
            "${WORKORDER_PYTHON}"
        DEPENDS build
        COMMENT "Create WorkOrder.app bundle for macOS (Type=${Type})"
        VERBATIM
    )
endif()

workorder_add_run_target(run-desktop desktop)
workorder_add_run_target(run-mobile mobile)

if(APPLE)
    add_custom_target(run
        COMMAND "${CMAKE_BINARY_DIR}/WorkOrder-${Type}.app/Contents/MacOS/WorkOrder-${Type}"
        DEPENDS "app-bundle-${Type}"
        COMMENT "Run WorkOrder (${Type}) via WorkOrder-${Type}.app"
        VERBATIM
    )
else()
    add_custom_target(run
        COMMAND chmod +x "${CMAKE_SOURCE_DIR}/scripts/run_workorder.sh"
        COMMAND ${CMAKE_COMMAND} -E env
            "WORKORDER_BUILD_DIR=${CMAKE_BINARY_DIR}"
            "${CMAKE_SOURCE_DIR}/scripts/run_workorder.sh"
            ${Type}
            "${CMAKE_BINARY_DIR}"
        WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
        DEPENDS build
        COMMENT "Run WorkOrder (${Type}, from cache variable Type)"
        VERBATIM
    )
endif()

add_custom_target(install-deps
    COMMAND ${Python3_EXECUTABLE} -m venv --clear "${CMAKE_SOURCE_DIR}/.venv"
    COMMAND "${CMAKE_SOURCE_DIR}/.venv/bin/python3" -m ensurepip --upgrade
    COMMAND "${CMAKE_SOURCE_DIR}/.venv/bin/python3" -m pip install -r "${CMAKE_SOURCE_DIR}/requirements.txt"
    WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
    COMMENT "Recreate .venv and install Python dependencies"
    VERBATIM
)

add_custom_target(test
    COMMAND ${WORKORDER_PYTHON} -m unittest discover -s tests -v
    WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
    COMMENT "Run unit tests"
    VERBATIM
)

message(STATUS "WorkOrder configured: default Type=${Type}")
if(WORKORDER_PYQT6_FOUND)
    message(STATUS "Run desktop: cmake --build ${CMAKE_BINARY_DIR} --target run-desktop")
    message(STATUS "Run mobile:  cmake --build ${CMAKE_BINARY_DIR} --target run-mobile")
else()
    message(STATUS "Run install-deps first, then Reconfigure CMake")
endif()
