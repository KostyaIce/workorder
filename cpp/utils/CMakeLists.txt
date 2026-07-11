cmake_minimum_required(VERSION 3.16)

set(WORKORDER_UTILS_SOURCES
    appPaths.cpp
    appLogging.cpp
    clientsDatabase.cpp
    databaseStorage.cpp
    minimalZip.cpp
    objectsDatabase.cpp
    pdfReportBuilder.cpp
    qSettingsStore.cpp
    reportBuilder.cpp
    serviceUnits.cpp
    servicesDatabase.cpp
    servicesExcelBuilder.cpp
    servicesPdfBuilder.cpp
    worksDatabase.cpp
)

set(WORKORDER_UTILS_HEADERS
    appPaths.h
    appLogging.h
    clientsDatabase.h
    databaseStorage.h
    minimalZip.h
    objectsDatabase.h
    pdfReportBuilder.h
    qSettingsStore.h
    reportBuilder.h
    serviceUnits.h
    servicesDatabase.h
    servicesExcelBuilder.h
    servicesPdfBuilder.h
    types.h
    worksDatabase.h
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
