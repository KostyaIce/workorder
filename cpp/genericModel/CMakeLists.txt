cmake_minimum_required(VERSION 3.16)

add_library(workorder_generic_model STATIC
    genericItem.h
    genericModel.h
    genericModelBase.h
    genericModelImpl.h
)

add_library(WorkOrder::GenericModel ALIAS workorder_generic_model)

target_compile_features(workorder_generic_model PUBLIC cxx_std_20)

target_link_libraries(workorder_generic_model
    PUBLIC
        Qt6::Core
)

target_include_directories(workorder_generic_model
    PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}
)

set_target_properties(workorder_generic_model PROPERTIES
    AUTOMOC ON
    AUTORCC OFF
    AUTOUIC OFF
    FOLDER "Project/C++"
)
