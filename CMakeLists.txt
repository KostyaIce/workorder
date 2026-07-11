cmake_minimum_required(VERSION 3.16)

if(NOT DEFINED WORKORDER_CMAKE_PRESET)
    set(WORKORDER_CMAKE_PRESET "python" CACHE STRING "WorkOrder project: python or cpp")
    set_property(CACHE WORKORDER_CMAKE_PRESET PROPERTY STRINGS python cpp)
endif()

if(WORKORDER_CMAKE_PRESET STREQUAL "python")
    include("${CMAKE_CURRENT_LIST_DIR}/python/CMakeLists.txt")
elseif(WORKORDER_CMAKE_PRESET STREQUAL "cpp")
    include("${CMAKE_CURRENT_LIST_DIR}/cpp/CMakeLists.txt")
else()
    message(FATAL_ERROR
        "Unknown WORKORDER_CMAKE_PRESET='${WORKORDER_CMAKE_PRESET}'. Use 'python' or 'cpp'.\n"
        "Or open python/CMakeLists.txt / cpp/CMakeLists.txt directly in Qt Creator."
    )
endif()
