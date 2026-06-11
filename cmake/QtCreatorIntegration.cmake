# Qt Creator / QML IDE integration helpers for Python+PyQt6 project.

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
        file(GLOB _qt_installs "$ENV{HOME}/Qt/*/macos")
        if(_qt_installs)
            list(SORT _qt_installs)
            list(REVERSE _qt_installs)
            foreach(_install IN LISTS _qt_installs)
                list(APPEND _candidates "${_install}")
            endforeach()
        endif()
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

# Macro: find_package results must stay in caller scope for CMakeLists.txt.
macro(workorder_find_qt6)
    workorder_collect_qt_prefix_candidates(_qt_prefixes)

    if(_qt_prefixes)
        list(PREPEND CMAKE_PREFIX_PATH ${_qt_prefixes})
        list(REMOVE_DUPLICATES CMAKE_PREFIX_PATH)
        set(CMAKE_PREFIX_PATH "${CMAKE_PREFIX_PATH}" CACHE STRING "Qt install prefixes" FORCE)
        message(STATUS "Qt prefix candidates: ${_qt_prefixes}")
    endif()

    find_package(Qt6 6.4 COMPONENTS Quick Qml QUIET)

    if(NOT Qt6_FOUND)
        message(WARNING
            "Qt6 not found. QML preview and completion in Qt Creator will be limited.\n"
            "  - Select kit \"Qt 6.x for macOS\" (not Generic)\n"
            "  - Or use preset \"Desktop + Qt 6.8.3\"\n"
            "  - Or set CMAKE_PREFIX_PATH to Qt install, e.g. ~/Qt/6.8.3/macos"
        )
    endif()
endmacro()

macro(workorder_setup_qml_import_path qml_dir)
    set(_paths
        "${CMAKE_SOURCE_DIR}/resources/qml"
        "${qml_dir}"
    )

    if(Qt6_FOUND AND DEFINED Qt6Quick_DIR)
        get_filename_component(_qt_root "${Qt6Quick_DIR}/../../../" ABSOLUTE)
        list(APPEND _paths "${_qt_root}/qml")
    endif()

    set(QML_IMPORT_PATH "${_paths}" CACHE STRING "QML import path for Qt Creator" FORCE)
    message(STATUS "QML_IMPORT_PATH=${QML_IMPORT_PATH}")
endmacro()
