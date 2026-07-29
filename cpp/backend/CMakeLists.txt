cmake_minimum_required(VERSION 3.16)

set(WORKORDER_BACKEND_SOURCES
    ../app/ApplicationBootstrap.cpp
    BackendController.cpp
    CloudDiskBackend.cpp
    DatabaseBackend.cpp
    InvoiceBackend.cpp
    NotificationManager.cpp
    ReportBackend.cpp
    ReportOptionsBackend.cpp
    SettingsBackend.cpp
)

set(WORKORDER_BACKEND_HEADERS
    ../app/ApplicationBootstrap.h
    BackendController.h
    CloudDiskBackend.h
    DatabaseBackend.h
    InvoiceBackend.h
    NotificationManager.h
    ReportBackend.h
    ReportOptionsBackend.h
    SettingsBackend.h
)

add_library(workorder_backend STATIC
    ${WORKORDER_BACKEND_SOURCES}
    ${WORKORDER_BACKEND_HEADERS}
)

add_library(WorkOrder::Backend ALIAS workorder_backend)

target_compile_features(workorder_backend PUBLIC cxx_std_20)

target_link_libraries(workorder_backend
    PUBLIC
        WorkOrder::Models
        WorkOrder::Utils
        Qt6::Core
        Qt6::Gui
        Qt6::Network
        Qt6::Qml
        Qt6::Quick
)

target_include_directories(workorder_backend
    PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}
        ${CMAKE_CURRENT_SOURCE_DIR}/..
        ${CMAKE_CURRENT_SOURCE_DIR}/../app
        ${CMAKE_CURRENT_SOURCE_DIR}/../models
        ${CMAKE_CURRENT_SOURCE_DIR}/../models/filters
        ${CMAKE_CURRENT_SOURCE_DIR}/../genericModel
        ${CMAKE_CURRENT_SOURCE_DIR}/../utils
)

set_target_properties(workorder_backend PROPERTIES
    AUTOMOC ON
    AUTORCC OFF
    AUTOUIC OFF
    FOLDER "Project/C++"
)
