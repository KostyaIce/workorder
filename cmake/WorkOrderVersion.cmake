# Load application version from version.mk (single source of truth).
# Requires WORKORDER_ROOT to be set (see WorkOrderRoot.cmake).

include_guard(GLOBAL)

if(NOT DEFINED WORKORDER_ROOT)
    message(FATAL_ERROR "WorkOrderVersion.cmake: WORKORDER_ROOT is not set")
endif()

include("${CMAKE_CURRENT_LIST_DIR}/ReadMKFile.cmake")

set(_workorder_version_mk "${WORKORDER_ROOT}/version.mk")
if(NOT EXISTS "${_workorder_version_mk}")
    message(FATAL_ERROR "version.mk not found: ${_workorder_version_mk}")
endif()

ReadVariables("${_workorder_version_mk}")

if(NOT DEFINED VERSION_MAJOR OR NOT DEFINED VERSION_MINOR OR NOT DEFINED VERSION_PATCH)
    message(FATAL_ERROR "version.mk must define VERSION_MAJOR, VERSION_MINOR, VERSION_PATCH")
endif()

set(WORKORDER_VERSION "${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}")
# Android uses the same version format as iOS: 1.0.27 / 1000027.
set(WORKORDER_VERSION_NAME "${WORKORDER_VERSION}")
if(VERSION_MINOR GREATER_EQUAL 1000 OR VERSION_PATCH GREATER_EQUAL 1000)
    message(FATAL_ERROR "Version minor and patch must be below 1000")
endif()
math(EXPR WORKORDER_VERSION_CODE
    "${VERSION_MAJOR} * 1000000 + ${VERSION_MINOR} * 1000 + ${VERSION_PATCH}")
if(ANDROID AND WORKORDER_VERSION_CODE GREATER 2100000000)
    message(FATAL_ERROR "Android versionCode exceeds 2100000000")
endif()

message(STATUS "WorkOrder version: ${WORKORDER_VERSION} (name=${WORKORDER_VERSION_NAME}, code=${WORKORDER_VERSION_CODE})")

# Global compile definitions for all targets created after this include.
add_compile_definitions(
    WORKORDER_VERSION="${WORKORDER_VERSION}"
    WORKORDER_VERSION_MAJOR=${VERSION_MAJOR}
    WORKORDER_VERSION_MINOR=${VERSION_MINOR}
    WORKORDER_VERSION_PATCH=${VERSION_PATCH}
)
