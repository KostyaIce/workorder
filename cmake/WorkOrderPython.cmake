function(workorder_python_candidates out_var)
    set(_candidates)

    foreach(_name IN ITEMS python3 python python3.13 python3.12 python3.11 python3.10)
        set(_path "${CMAKE_SOURCE_DIR}/.venv/bin/${_name}")
        if(EXISTS "${_path}")
            list(APPEND _candidates "${_path}")
        endif()
    endforeach()

    file(GLOB _venv_pythons "${CMAKE_SOURCE_DIR}/.venv/bin/python*")
    foreach(_path IN LISTS _venv_pythons)
        if(_path MATCHES "(python-config|pythonw|\\.py$)$")
            continue()
        endif()
        list(APPEND _candidates "${_path}")
    endforeach()

    if(Python3_EXECUTABLE)
        list(APPEND _candidates "${Python3_EXECUTABLE}")
    endif()

    list(REMOVE_DUPLICATES _candidates)
    set(${out_var} "${_candidates}" PARENT_SCOPE)
endfunction()

function(workorder_python_has_qt python out_var)
    if(NOT EXISTS "${python}")
        set(${out_var} FALSE PARENT_SCOPE)
        return()
    endif()

    execute_process(
        COMMAND "${python}" -c "import qt_compat; import reportlab; import openpyxl"
        RESULT_VARIABLE _result
        OUTPUT_QUIET
        ERROR_QUIET
        WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}/src"
        TIMEOUT 15
    )
    if(_result EQUAL 0)
        set(${out_var} TRUE PARENT_SCOPE)
    else()
        execute_process(
            COMMAND "${python}" -c "import PyQt6; import reportlab; import openpyxl"
            RESULT_VARIABLE _result
            OUTPUT_QUIET
            ERROR_QUIET
            TIMEOUT 15
        )
        if(_result EQUAL 0)
            set(${out_var} TRUE PARENT_SCOPE)
        else()
            set(${out_var} FALSE PARENT_SCOPE)
        endif()
    endif()
endfunction()

function(workorder_resolve_python out_python out_found)
    workorder_python_candidates(_candidates)

    set(_selected "")
    foreach(_python IN LISTS _candidates)
        workorder_python_has_qt("${_python}" _has_qt)
        if(_has_qt)
            set(_selected "${_python}")
            break()
        endif()
    endforeach()

    if(_selected)
        set(${out_python} "${_selected}" PARENT_SCOPE)
        set(${out_found} TRUE PARENT_SCOPE)
        return()
    endif()

    if(Python3_EXECUTABLE)
        set(${out_python} "${Python3_EXECUTABLE}" PARENT_SCOPE)
    else()
        set(${out_python} "" PARENT_SCOPE)
    endif()
    set(${out_found} FALSE PARENT_SCOPE)
endfunction()
