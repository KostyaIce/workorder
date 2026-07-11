# Shared Qt Creator / QML IDE helpers for WorkOrder subprojects.

function(workorder_collect_qt_prefix_candidates out_var)
    set(_candidates)

    if(DEFINED ENV{QTDIR})
        list(APPEND _candidates "$ENV{QTDIR}")
    endif()

    if(DEFINED ENV{Qt6_DIR})
        get_filename_component(_qt6_root "$ENV{Qt6_DIR}/../../.." ABSOLUTE)
        list(APPEND _candidates "${_qt6_root}")
    endif()

    if(CMAKE_PREFIX_PATH)
        list(APPEND _candidates ${CMAKE_PREFIX_PATH})
    endif()

    if(EXISTS "/opt/homebrew/opt/qt/lib/cmake/Qt6")
        list(APPEND _candidates "/opt/homebrew/opt/qt")
    elseif(EXISTS "/opt/homebrew/opt/qt@6/lib/cmake/Qt6")
        list(APPEND _candidates "/opt/homebrew/opt/qt@6")
    endif()

    if(EXISTS "/usr/local/opt/qt/lib/cmake/Qt6")
        list(APPEND _candidates "/usr/local/opt/qt")
    elseif(EXISTS "/usr/local/opt/qt@6/lib/cmake/Qt6")
        list(APPEND _candidates "/usr/local/opt/qt@6")
    endif()

    if(DEFINED ENV{HOME})
        foreach(_qt_subdir macos gcc_64)
            file(GLOB _qt_installs "$ENV{HOME}/Qt/*/${_qt_subdir}")
            if(_qt_installs)
                list(SORT _qt_installs)
                list(REVERSE _qt_installs)
                foreach(_install IN LISTS _qt_installs)
                    list(APPEND _candidates "${_install}")
                endforeach()
            endif()
        endforeach()
    endif()

    set(_verified)
    foreach(_prefix IN LISTS _candidates)
        if(NOT _prefix)
            continue()
        endif()
        get_filename_component(_prefix_abs "${_prefix}" ABSOLUTE)
        if(EXISTS "${_prefix_abs}/lib/cmake/Qt6/Qt6Config.cmake")
            list(APPEND _verified "${_prefix_abs}")
        endif()
    endforeach()

    if(_verified)
        list(REMOVE_DUPLICATES _verified)
    endif()

    set(${out_var} "${_verified}" PARENT_SCOPE)
endfunction()

function(workorder_apply_qt_prefix_path)
    workorder_collect_qt_prefix_candidates(_qt_prefixes)

    if(_qt_prefixes)
        list(PREPEND CMAKE_PREFIX_PATH ${_qt_prefixes})
        list(REMOVE_DUPLICATES CMAKE_PREFIX_PATH)
        set(CMAKE_PREFIX_PATH "${CMAKE_PREFIX_PATH}" CACHE STRING "Qt install prefixes" FORCE)
        message(STATUS "Qt prefix candidates: ${_qt_prefixes}")
    endif()
endfunction()

macro(workorder_find_qt6_for_qml)
    workorder_apply_qt_prefix_path()
    find_package(Qt6 6.4 COMPONENTS Quick Qml QUIET)

    if(NOT Qt6_FOUND)
        message(WARNING
            "Qt6 not found. QML preview and completion in Qt Creator will be limited.\n"
            "  - Select kit \"Qt 6.x\" with Quick/Qml (not Generic)\n"
            "  - Or set CMAKE_PREFIX_PATH to Qt install, e.g. ~/Qt/6.8.3/gcc_64"
        )
    endif()
endmacro()

function(workorder_filter_project_files in_out_var)
    list(FILTER ${in_out_var} EXCLUDE REGEX "/\\._")
    list(FILTER ${in_out_var} EXCLUDE REGEX "__pycache__")
endfunction()

function(workorder_collect_project_sources out_all out_desktop out_mobile out_common)
    file(GLOB_RECURSE _python_sources CONFIGURE_DEPENDS
        "${WORKORDER_ROOT}/src/*.py"
    )
    file(GLOB_RECURSE _cpp_sources CONFIGURE_DEPENDS
        "${WORKORDER_ROOT}/cpp/*.cpp"
        "${WORKORDER_ROOT}/cpp/*.h"
    )
    file(GLOB_RECURSE _desktop_qml CONFIGURE_DEPENDS
        "${WORKORDER_ROOT}/resources/qml/desktop/*.qml"
    )
    file(GLOB_RECURSE _mobile_qml CONFIGURE_DEPENDS
        "${WORKORDER_ROOT}/resources/qml/mobile/*.qml"
    )
    file(GLOB_RECURSE _common_qml CONFIGURE_DEPENDS
        "${WORKORDER_ROOT}/resources/qml/WorkOrder/*.qml"
    )
    file(GLOB _desktop_qmldir CONFIGURE_DEPENDS
        "${WORKORDER_ROOT}/resources/qml/desktop/qmldir"
    )
    file(GLOB _mobile_qmldir CONFIGURE_DEPENDS
        "${WORKORDER_ROOT}/resources/qml/mobile/qmldir"
    )
    file(GLOB _common_qmldir CONFIGURE_DEPENDS
        "${WORKORDER_ROOT}/resources/qml/WorkOrder/Common/qmldir"
    )
    file(GLOB_RECURSE _tests CONFIGURE_DEPENDS
        "${WORKORDER_ROOT}/tests/*.py"
    )

    foreach(_list IN ITEMS
        _python_sources _cpp_sources
        _desktop_qml _mobile_qml _common_qml
        _desktop_qmldir _mobile_qmldir _common_qmldir
        _tests
    )
        workorder_filter_project_files(_list)
    endforeach()

    set(_desktop_sources ${_desktop_qml} ${_desktop_qmldir})
    set(_mobile_sources ${_mobile_qml} ${_mobile_qmldir})
    set(_common_sources ${_common_qml} ${_common_qmldir})
    set(_shared
        ${_python_sources}
        ${_cpp_sources}
        ${_tests}
        ${WORKORDER_ROOT}/resources/icons/appIcons/icon_macos.icns
        ${WORKORDER_ROOT}/resources/icons/appIcons/icon_win32.ico
        ${WORKORDER_ROOT}/resources/icons/appIcons/icon_linux.png
        ${WORKORDER_ROOT}/requirements.txt
        ${WORKORDER_ROOT}/README.md
    )
    set(_all
        ${_shared}
        ${_desktop_sources}
        ${_mobile_sources}
        ${_common_sources}
    )
    list(SORT _all)
    list(SORT _desktop_sources)
    list(SORT _mobile_sources)
    list(SORT _common_sources)

    set(${out_all} "${_all}" PARENT_SCOPE)
    set(${out_desktop} "${_desktop_sources}" PARENT_SCOPE)
    set(${out_mobile} "${_mobile_sources}" PARENT_SCOPE)
    set(${out_common} "${_common_sources}" PARENT_SCOPE)
endfunction()

function(workorder_apply_source_groups)
    cmake_parse_arguments(_args "" "" "FILES;DESKTOP;MOBILE;COMMON;PYTHON;CPP;TESTS" ${ARGN})

    if(_args_DESKTOP)
        source_group(TREE "${WORKORDER_ROOT}/resources/qml/desktop"
            PREFIX "UI/Desktop"
            FILES ${_args_DESKTOP}
        )
    endif()

    if(_args_MOBILE)
        source_group(TREE "${WORKORDER_ROOT}/resources/qml/mobile"
            PREFIX "UI/Mobile (compact)"
            FILES ${_args_MOBILE}
        )
    endif()

    if(_args_COMMON)
        source_group(TREE "${WORKORDER_ROOT}/resources/qml/WorkOrder"
            PREFIX "UI/Common"
            FILES ${_args_COMMON}
        )
    endif()

    if(_args_PYTHON)
        source_group(TREE "${WORKORDER_ROOT}/src"
            PREFIX "Python"
            FILES ${_args_PYTHON}
        )
    endif()

    if(_args_CPP)
        source_group(TREE "${WORKORDER_ROOT}/cpp"
            PREFIX "C++"
            FILES ${_args_CPP}
        )
    endif()

    if(_args_TESTS)
        source_group(TREE "${WORKORDER_ROOT}/tests"
            PREFIX "Tests"
            FILES ${_args_TESTS}
        )
    endif()
endfunction()

function(workorder_register_ide_sources target)
    if(NOT TARGET ${target})
        return()
    endif()

    cmake_parse_arguments(_args "" "" "FILES" ${ARGN})
    if(NOT _args_FILES)
        return()
    endif()

    target_sources(${target} PRIVATE ${_args_FILES})

    foreach(_file IN LISTS _args_FILES)
        if(_file MATCHES "\\.qml$")
            set_source_files_properties("${_file}" PROPERTIES
                SKIP_AUTOMOC ON
                SKIP_AUTOUIC ON
            )
        endif()
    endforeach()
endfunction()

macro(workorder_setup_qml_import_path qml_dir)
    set(_paths
        "${WORKORDER_ROOT}/resources/qml"
        "${WORKORDER_ROOT}/resources/qml/desktop"
        "${WORKORDER_ROOT}/resources/qml/mobile"
        "${qml_dir}"
    )

    if(Qt6_FOUND AND DEFINED Qt6Quick_DIR)
        get_filename_component(_qt_root "${Qt6Quick_DIR}/../../../" ABSOLUTE)
        list(APPEND _paths "${_qt_root}/qml")
    endif()

    list(REMOVE_DUPLICATES _paths)

    set(QML_IMPORT_PATH "${_paths}" CACHE STRING "QML import path for Qt Creator" FORCE)
    message(STATUS "QML_IMPORT_PATH=${QML_IMPORT_PATH}")
endmacro()
