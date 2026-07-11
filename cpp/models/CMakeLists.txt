cmake_minimum_required(VERSION 3.16)

set(WORKORDER_MODELS_SOURCES
    clientsModel.cpp
    objectsModel.cpp
    servicesModel.cpp
    worksModel.cpp
    ordersModel.cpp
    subobjectsModel.cpp
    filters/textFilterProxyModel.cpp
    filters/servicesFilterModel.cpp
    filters/coefficientsFilterModel.cpp
    filters/subobjectsFilterModel.cpp
)

set(WORKORDER_MODELS_HEADERS
    clientsModel.h
    objectsModel.h
    servicesModel.h
    worksModel.h
    ordersModel.h
    subobjectsModel.h
    modelUtils.h
    items/clientItem.h
    items/objectItem.h
    items/serviceItem.h
    items/workItem.h
    items/orderItem.h
    items/subobjectItem.h
    filters/textFilterProxyModel.h
    filters/servicesFilterModel.h
    filters/coefficientsFilterModel.h
    filters/subobjectsFilterModel.h
)

add_library(workorder_models STATIC
    ${WORKORDER_MODELS_SOURCES}
    ${WORKORDER_MODELS_HEADERS}
)

add_library(WorkOrder::Models ALIAS workorder_models)

target_compile_features(workorder_models PUBLIC cxx_std_20)

target_link_libraries(workorder_models
    PUBLIC
        WorkOrder::GenericModel
        WorkOrder::Utils
        Qt6::Core
)

target_include_directories(workorder_models
    PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}
        ${CMAKE_CURRENT_SOURCE_DIR}/../genericModel
        ${CMAKE_CURRENT_SOURCE_DIR}/../utils
)

set_target_properties(workorder_models PROPERTIES
    AUTOMOC ON
    AUTORCC OFF
    AUTOUIC OFF
    FOLDER "Project/C++"
)
