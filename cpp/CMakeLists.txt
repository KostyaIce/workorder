cmake_minimum_required(VERSION 3.16)

project(WorkOrder
    VERSION 1.0.0
    DESCRIPTION "WorkOrder C++ application"
    LANGUAGES CXX
)

include("${CMAKE_CURRENT_LIST_DIR}/../cmake/WorkOrderRoot.cmake")
include("${WORKORDER_ROOT}/cmake/IdeCommon.cmake")
include("${WORKORDER_ROOT}/cmake/CppProject.cmake")
include("${WORKORDER_ROOT}/cmake/CppResources.cmake")
include("${WORKORDER_ROOT}/cmake/CppAndroid.cmake")

if(ANDROID)
    set(Type "mobile" CACHE STRING "Application UI type on Android" FORCE)
else()
    set(Type "desktop" CACHE STRING "Default UI type for generic run target: desktop or mobile")
endif()
set_property(CACHE Type PROPERTY STRINGS desktop mobile)

if(NOT Type MATCHES "^(desktop|mobile)$")
    message(FATAL_ERROR "Type must be 'desktop' or 'mobile', got: '${Type}'")
endif()

workorder_find_qt6_cpp()
qt_standard_project_setup(REQUIRES 6.5)

set(QML_DIR "${WORKORDER_ROOT}/resources/qml/${Type}")
workorder_setup_qml_import_path("${QML_DIR}")

workorder_collect_project_sources(
    ALL_SOURCES
    DESKTOP_SOURCES
    MOBILE_SOURCES
    COMMON_SOURCES
)

file(GLOB_RECURSE CPP_SOURCES CONFIGURE_DEPENDS
    "${CMAKE_CURRENT_LIST_DIR}/*.cpp"
    "${CMAKE_CURRENT_LIST_DIR}/*.h"
)
workorder_filter_project_files(CPP_SOURCES)

workorder_apply_source_groups(
    DESKTOP ${DESKTOP_SOURCES}
    MOBILE ${MOBILE_SOURCES}
    COMMON ${COMMON_SOURCES}
    CPP ${CPP_SOURCES}
)

add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/genericModel)
add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/utils)
add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/models)
add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/backend)

qt_add_executable(WorkOrder
    ${CMAKE_CURRENT_LIST_DIR}/main.cpp
)

target_link_libraries(WorkOrder
    PRIVATE
        WorkOrder::Backend
        Qt6::Core
)

if(TARGET Qt6::Pdf AND NOT ANDROID)
    target_link_libraries(WorkOrder PRIVATE Qt6::Pdf)
endif()

set_target_properties(WorkOrder PROPERTIES
    AUTOMOC OFF
    FOLDER "qtc_runnable"
)

workorder_setup_qrc_resources(WorkOrder)

if(ANDROID)
    workorder_setup_android_target(WorkOrder)
endif()

if(ANDROID)
    add_custom_target(build ALL
        DEPENDS WorkOrder
        COMMENT "Build WorkOrder C++ for Android"
    )
else()
    add_custom_target(build ALL
        DEPENDS WorkOrder
        COMMENT "Build WorkOrder C++"
    )
endif()
set_target_properties(build PROPERTIES FOLDER "Project/Build")

workorder_register_ide_sources(build FILES ${ALL_SOURCES})

add_custom_target(desktop-ui SOURCES ${DESKTOP_SOURCES})
add_custom_target(mobile-ui SOURCES ${MOBILE_SOURCES})
add_custom_target(common-ui SOURCES ${COMMON_SOURCES})

if(ANDROID)
    workorder_add_android_run_target(run-android-apk)
else()
    workorder_add_cpp_run_target(run-desktop desktop)
    workorder_add_cpp_run_target(run-mobile mobile)
endif()

if(NOT ANDROID)
    add_custom_target(run
        COMMAND "$<TARGET_FILE:WorkOrder>" --type ${Type}
        DEPENDS WorkOrder
        WORKING_DIRECTORY "${WORKORDER_ROOT}"
        COMMENT "Run WorkOrder C++ (${Type}, from cache variable Type)"
        VERBATIM
    )
    set_target_properties(run PROPERTIES FOLDER "qtc_runnable")
endif()

message(STATUS "WorkOrder C++ configured: Type=${Type}, ANDROID=${ANDROID}")
if(ANDROID)
    message(STATUS "Build APK: cmake --build ${CMAKE_BINARY_DIR} --target WorkOrder_make_apk")
    message(STATUS "Or target: run-android-apk")
else()
    message(STATUS "Run desktop: cmake --build ${CMAKE_BINARY_DIR} --target run-desktop")
    message(STATUS "Run mobile:  cmake --build ${CMAKE_BINARY_DIR} --target run-mobile")
endif()
