# Qt logging category filter rules for AppLogging (qInstallMessageHandler).
#
# Cache variables (clients / CI):
#   WORKORDER_QT_LOGGING_VERBOSE=ON  — keep qt.*.debug/info (QML import spam etc.)
#   WORKORDER_QT_LOGGING_RULES=...   — full custom rules string (overrides VERBOSE preset)
#
# Runtime override (no rebuild): env QT_LOGGING_RULES
#   export QT_LOGGING_RULES='*.debug=true
#   qt.qml.import.debug=true'

include_guard(GLOBAL)

option(WORKORDER_QT_LOGGING_VERBOSE
    "Enable Qt framework debug/info categories (for client debugging)"
    OFF)

set(WORKORDER_QT_LOGGING_RULES "" CACHE STRING
    "Custom Qt QLoggingCategory filter rules (empty = use VERBOSE preset)")

set(_WORKORDER_LOGGING_RULES_DEFAULT
    "*.debug=true
*.info=true
*.warning=true
*.critical=true
qt.*.debug=false
qt.*.info=false")

set(_WORKORDER_LOGGING_RULES_VERBOSE
    "*.debug=true
*.info=true
*.warning=true
*.critical=true")

if(WORKORDER_QT_LOGGING_RULES STREQUAL "")
    if(WORKORDER_QT_LOGGING_VERBOSE)
        set(WORKORDER_QT_LOGGING_RULES_CONTENT "${_WORKORDER_LOGGING_RULES_VERBOSE}")
    else()
        set(WORKORDER_QT_LOGGING_RULES_CONTENT "${_WORKORDER_LOGGING_RULES_DEFAULT}")
    endif()
else()
    set(WORKORDER_QT_LOGGING_RULES_CONTENT "${WORKORDER_QT_LOGGING_RULES}")
endif()

set(_workorder_logging_gen_dir "${CMAKE_BINARY_DIR}/generated")
file(MAKE_DIRECTORY "${_workorder_logging_gen_dir}")

configure_file(
    "${CMAKE_CURRENT_LIST_DIR}/WorkOrderLoggingRules.h.in"
    "${_workorder_logging_gen_dir}/WorkOrderLoggingRules.h"
    @ONLY
)

set(WORKORDER_LOGGING_GENERATED_INCLUDE_DIR "${_workorder_logging_gen_dir}" CACHE INTERNAL "")

message(STATUS "WorkOrder Qt logging verbose=${WORKORDER_QT_LOGGING_VERBOSE}")
if(WORKORDER_QT_LOGGING_VERBOSE OR NOT WORKORDER_QT_LOGGING_RULES STREQUAL "")
    message(STATUS "WorkOrder Qt logging rules:\n${WORKORDER_QT_LOGGING_RULES_CONTENT}")
endif()
