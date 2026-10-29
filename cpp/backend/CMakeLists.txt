cmake_minimum_required(VERSION 3.16)

set(WORKORDER_BACKEND_SOURCES
    ../app/ApplicationBootstrap.cpp
    ../app/ScreenInsets.cpp
    BackendController.cpp
    CloudDiskBackend.cpp
    YandexDiskOAuthFlow.cpp
    DatabaseBackend.cpp
    InvoiceBackend.cpp
    NotificationManager.cpp
    ReportBackend.cpp
    ReportOptionsBackend.cpp
    SettingsBackend.cpp
)

set(WORKORDER_BACKEND_HEADERS
    ../app/ApplicationBootstrap.h
    ../app/ScreenInsets.h
    BackendController.h
    CloudDiskBackend.h
    YandexDiskConfig.h
    YandexDiskOAuthFlow.h
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

if(WORKORDER_YANDEX_OAUTH_CLIENT_ID)
    target_compile_definitions(workorder_backend
        PRIVATE WORKORDER_YANDEX_OAUTH_CLIENT_ID="${WORKORDER_YANDEX_OAUTH_CLIENT_ID}")
endif()
if(WORKORDER_MOBILE_APPLICATION_ID)
    target_compile_definitions(workorder_backend
        PRIVATE WORKORDER_MOBILE_APPLICATION_ID="${WORKORDER_MOBILE_APPLICATION_ID}")
endif()
if(WORKORDER_OAUTH_CALLBACK_SCHEME)
    target_compile_definitions(workorder_backend
        PRIVATE WORKORDER_OAUTH_CALLBACK_SCHEME="${WORKORDER_OAUTH_CALLBACK_SCHEME}")
endif()

target_link_libraries(workorder_backend
    PUBLIC
        WorkOrder::Models
        WorkOrder::Utils
        Qt6::Core
        Qt6::Gui
        Qt6::GuiPrivate
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
