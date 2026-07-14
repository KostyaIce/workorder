# QML/fonts packaged into Qt resources for all WorkOrder C++ targets.

function(workorder_setup_qrc_resources target)
    if(NOT TARGET ${target})
        message(FATAL_ERROR "workorder_setup_qrc_resources: target '${target}' not found")
    endif()

    file(GLOB_RECURSE _qml_desktop CONFIGURE_DEPENDS
        "${WORKORDER_ROOT}/resources/qml/desktop/*.qml"
        "${WORKORDER_ROOT}/resources/qml/desktop/qmldir"
    )
    file(GLOB_RECURSE _qml_mobile CONFIGURE_DEPENDS
        "${WORKORDER_ROOT}/resources/qml/mobile/*.qml"
        "${WORKORDER_ROOT}/resources/qml/mobile/qmldir"
    )
    file(GLOB_RECURSE _qml_common CONFIGURE_DEPENDS
        "${WORKORDER_ROOT}/resources/qml/WorkOrder/Common/*.qml"
        "${WORKORDER_ROOT}/resources/qml/WorkOrder/Common/qmldir"
    )
    file(GLOB _fonts CONFIGURE_DEPENDS
        "${WORKORDER_ROOT}/resources/fonts/*.ttf"
    )
    file(GLOB _app_icons CONFIGURE_DEPENDS
        "${WORKORDER_ROOT}/resources/icons/appIcons/icon_linux.png"
        "${WORKORDER_ROOT}/resources/icons/appIcons/icon_win32.ico"
        "${WORKORDER_ROOT}/resources/icons/appIcons/icon_macos.icns"
    )

    qt_add_resources(${target} "workorder_qml_assets"
        PREFIX "/"
        BASE "${WORKORDER_ROOT}"
        FILES
            ${_qml_desktop}
            ${_qml_mobile}
            ${_qml_common}
            ${_fonts}
            ${_app_icons}
    )

    set_target_properties(${target} PROPERTIES AUTORCC ON)
    message(STATUS "QML, fonts and app icons bundled into qrc for ${target}")
endfunction()
