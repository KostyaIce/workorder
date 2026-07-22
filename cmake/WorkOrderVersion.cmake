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
# Android versionName style: MAJOR.MINOR-PATCH (same as dapchainvpn-client)
set(WORKORDER_VERSION_NAME "${VERSION_MAJOR}.${VERSION_MINOR}-${VERSION_PATCH}")
# versionCode: M mm ppp → e.g. 1.0.12 → 100012
math(EXPR WORKORDER_VERSION_CODE
    "${VERSION_MAJOR} * 100000 + ${VERSION_MINOR} * 1000 + ${VERSION_PATCH}")

message(STATUS "WorkOrder version: ${WORKORDER_VERSION} (name=${WORKORDER_VERSION_NAME}, code=${WORKORDER_VERSION_CODE})")

# Global compile definitions for all targets created after this include.
add_compile_definitions(
    WORKORDER_VERSION="${WORKORDER_VERSION}"
    WORKORDER_VERSION_MAJOR=${VERSION_MAJOR}
    WORKORDER_VERSION_MINOR=${VERSION_MINOR}
    WORKORDER_VERSION_PATCH=${VERSION_PATCH}
)
