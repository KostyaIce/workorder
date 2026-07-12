cmake_minimum_required(VERSION 3.16)

set(WORKORDER_UTILS_SOURCES
    AppPaths.cpp
    AppLogging.cpp
    ClientsDatabase.cpp
    DatabaseStorage.cpp
    MinimalZip.cpp
    ObjectsDatabase.cpp
    PdfReportBuilder.cpp
    QSettingsStore.cpp
    ReportBuilder.cpp
    ServiceUnits.cpp
    ServicesDatabase.cpp
    ServicesExcelBuilder.cpp
    ServicesPdfBuilder.cpp
    WorksDatabase.cpp
)

set(WORKORDER_UTILS_HEADERS
    AppPaths.h
    AppLogging.h
    ClientsDatabase.h
    DatabaseStorage.h
    MinimalZip.h
    ObjectsDatabase.h
    PdfReportBuilder.h
    QSettingsStore.h
    ReportBuilder.h
    ServiceUnits.h
    ServicesDatabase.h
    ServicesExcelBuilder.h
    ServicesPdfBuilder.h
    Types.h
    WorksDatabase.h
)

add_library(workorder_utils STATIC
    ${WORKORDER_UTILS_SOURCES}
    ${WORKORDER_UTILS_HEADERS}
)

add_library(WorkOrder::Utils ALIAS workorder_utils)

target_compile_features(workorder_utils PUBLIC cxx_std_17)

target_link_libraries(workorder_utils
    PUBLIC
        Qt6::Core
        Qt6::Sql
        Qt6::Gui
)

target_include_directories(workorder_utils
    PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}
)

set_target_properties(workorder_utils PROPERTIES
    AUTOMOC OFF
    AUTORCC OFF
    AUTOUIC OFF
    FOLDER "Project/C++"
)
