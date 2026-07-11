cmake_minimum_required(VERSION 3.16)

project(WorkOrderPython
    VERSION 1.0.0
    DESCRIPTION "WorkOrder Python/PyQt6 IDE and run targets"
    LANGUAGES C CXX
)

include("${CMAKE_CURRENT_LIST_DIR}/../cmake/WorkOrderRoot.cmake")
include("${WORKORDER_ROOT}/cmake/IdeCommon.cmake")
include("${WORKORDER_ROOT}/cmake/PythonProject.cmake")

set(Type "desktop" CACHE STRING "Default UI type for generic run target: desktop or mobile")
set_property(CACHE Type PROPERTY STRINGS desktop mobile)

if(NOT Type MATCHES "^(desktop|mobile)$")
    message(FATAL_ERROR "Type must be 'desktop' or 'mobile', got: '${Type}'")
endif()

find_package(Python3 REQUIRED COMPONENTS Interpreter)

workorder_resolve_python(WORKORDER_PYTHON WORKORDER_PYQT6_FOUND)
if(WORKORDER_PYQT6_FOUND)
    message(STATUS "Python runtime OK: ${WORKORDER_PYTHON}")
else()
    message(WARNING
        "Qt Python bindings or app deps missing (PyQt6/PySide6, reportlab, openpyxl).\n"
        "  Desktop: pip install -r requirements.txt\n"
        "  Android: pip install -r requirements-android.txt"
    )
endif()

workorder_find_qt6_for_qml()

set(QML_DIR "${WORKORDER_ROOT}/resources/qml/${Type}")

workorder_collect_project_sources(
    ALL_SOURCES
    DESKTOP_SOURCES
    MOBILE_SOURCES
    COMMON_SOURCES
)

file(GLOB_RECURSE PYTHON_SOURCES CONFIGURE_DEPENDS "${WORKORDER_ROOT}/src/*.py")
workorder_filter_project_files(PYTHON_SOURCES)
file(GLOB_RECURSE TEST_SOURCES CONFIGURE_DEPENDS "${WORKORDER_ROOT}/tests/*.py")
workorder_filter_project_files(TEST_SOURCES)

workorder_setup_qml_import_path("${QML_DIR}")

workorder_apply_source_groups(
    DESKTOP ${DESKTOP_SOURCES}
    MOBILE ${MOBILE_SOURCES}
    COMMON ${COMMON_SOURCES}
    PYTHON ${PYTHON_SOURCES}
    TESTS ${TEST_SOURCES}
)

add_custom_target(build ALL
    COMMAND ${CMAKE_COMMAND} -E echo "WorkOrder Python configured. Run targets: run-desktop, run-mobile."
    SOURCES ${ALL_SOURCES}
    COMMENT "Prepare WorkOrder Python"
    VERBATIM
)
set_target_properties(build PROPERTIES FOLDER "Project/Build")
workorder_register_ide_sources(build FILES ${ALL_SOURCES})

add_custom_target(desktop-ui SOURCES ${DESKTOP_SOURCES})
add_custom_target(mobile-ui SOURCES ${MOBILE_SOURCES})
add_custom_target(common-ui SOURCES ${COMMON_SOURCES})

add_library(workorder_ide STATIC EXCLUDE_FROM_ALL
    "${WORKORDER_ROOT}/cmake/ide_stub.cpp"
)
target_sources(workorder_ide PRIVATE ${ALL_SOURCES})
set_source_files_properties(${ALL_SOURCES} PROPERTIES HEADER_FILE_ONLY TRUE)
set_target_properties(workorder_ide PROPERTIES
    AUTOMOC OFF
    AUTORCC OFF
    AUTOUIC OFF
)

file(GENERATE OUTPUT "${CMAKE_BINARY_DIR}/workorder_config.py"
    CONTENT "APP_TYPE = '${Type}'\n"
)

configure_file(
    "${WORKORDER_ROOT}/cmake/config.py.in"
    "${CMAKE_BINARY_DIR}/workorder_build_info.py"
    @ONLY
)

if(APPLE)
    file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/macos")
    configure_file(
        "${WORKORDER_ROOT}/cmake/macos/Info.plist.in"
        "${CMAKE_BINARY_DIR}/macos/Info.plist"
        @ONLY
    )

    add_custom_target(app-bundle
        COMMAND chmod +x "${WORKORDER_ROOT}/scripts/macos/create_app_bundle.sh"
        COMMAND "${WORKORDER_ROOT}/scripts/macos/create_app_bundle.sh"
            "${WORKORDER_ROOT}"
            "${CMAKE_BINARY_DIR}"
            "${Type}"
            "${WORKORDER_PYTHON}"
        DEPENDS build
        COMMENT "Create WorkOrder.app bundle for macOS (Type=${Type})"
        VERBATIM
    )
endif()

workorder_add_python_run_target(run-desktop desktop)
workorder_add_python_run_target(run-mobile mobile)

if(APPLE)
    add_custom_target(run
        COMMAND "${CMAKE_BINARY_DIR}/WorkOrder-${Type}.app/Contents/MacOS/WorkOrder-${Type}"
        DEPENDS "app-bundle-${Type}"
        COMMENT "Run WorkOrder Python (${Type}) via WorkOrder-${Type}.app"
        VERBATIM
    )
else()
    add_custom_target(run
        COMMAND chmod +x "${WORKORDER_ROOT}/scripts/run_workorder.sh"
        COMMAND ${CMAKE_COMMAND} -E env
            "WORKORDER_BUILD_DIR=${CMAKE_BINARY_DIR}"
            "${WORKORDER_ROOT}/scripts/run_workorder.sh"
            ${Type}
            "${CMAKE_BINARY_DIR}"
        WORKING_DIRECTORY "${WORKORDER_ROOT}"
        DEPENDS build
        COMMENT "Run WorkOrder Python (${Type}, from cache variable Type)"
        VERBATIM
    )
endif()

set_target_properties(run PROPERTIES FOLDER "qtc_runnable")

add_custom_target(install-deps
    COMMAND ${Python3_EXECUTABLE} -m venv --clear "${WORKORDER_ROOT}/.venv"
    COMMAND "${WORKORDER_ROOT}/.venv/bin/python3" -m ensurepip --upgrade
    COMMAND "${WORKORDER_ROOT}/.venv/bin/python3" -m pip install -r "${WORKORDER_ROOT}/requirements.txt"
    WORKING_DIRECTORY "${WORKORDER_ROOT}"
    COMMENT "Recreate .venv and install Python dependencies"
    VERBATIM
)

add_custom_target(test
    COMMAND ${WORKORDER_PYTHON} -m unittest discover -s tests -v
    WORKING_DIRECTORY "${WORKORDER_ROOT}"
    COMMENT "Run unit tests"
    VERBATIM
)

message(STATUS "WorkOrder Python configured: default Type=${Type}")
if(WORKORDER_PYQT6_FOUND)
    message(STATUS "Run desktop: cmake --build ${CMAKE_BINARY_DIR} --target run-desktop")
    message(STATUS "Run mobile:  cmake --build ${CMAKE_BINARY_DIR} --target run-mobile")
else()
    message(STATUS "Run install-deps first, then Reconfigure CMake")
endif()
