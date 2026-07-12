cmake_minimum_required(VERSION 3.16)

set(WORKORDER_MODELS_SOURCES
    ClientsModel.cpp
    ObjectsModel.cpp
    ServicesModel.cpp
    WorksModel.cpp
    OrdersModel.cpp
    SubobjectsModel.cpp
    filters/TextFilterProxyModel.cpp
    filters/ServicesFilterModel.cpp
    filters/CoefficientsFilterModel.cpp
    filters/SubobjectsFilterModel.cpp
)

set(WORKORDER_MODELS_HEADERS
    ClientsModel.h
    ObjectsModel.h
    ServicesModel.h
    WorksModel.h
    OrdersModel.h
    SubobjectsModel.h
    ModelUtils.h
    items/ClientItem.h
    items/ObjectItem.h
    items/ServiceItem.h
    items/WorkItem.h
    items/OrderItem.h
    items/SubobjectItem.h
    filters/TextFilterProxyModel.h
    filters/ServicesFilterModel.h
    filters/CoefficientsFilterModel.h
    filters/SubobjectsFilterModel.h
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
