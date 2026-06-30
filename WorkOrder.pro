TEMPLATE = aux
CONFIG += qt quick qml_debug

QT += quick quickcontrols2

# Build type: desktop (default) or mobile
# Usage: qmake BUILD_TYPE=mobile
BUILD_TYPE = desktop
!isEmpty(BUILD_TYPE) {
    DEFINES += APP_BUILD_TYPE=\\\"$$BUILD_TYPE\\\"
}

QML_IMPORT_PATH = \
    $$PWD/resources/qml/desktop \
    $$PWD/resources/qml/mobile

DISTFILES += \
    CMakeLists.txt \
    CMakePresets.json \
    requirements.txt \
    README.md \
    src/main.py \
    src/app_paths.py \
    resources/icons/appIcons/icon_macos.icns \
    resources/icons/appIcons/icon_win32.ico \
    resources/icons/appIcons/icon_linux.png \
    src/backend/__init__.py \
    src/backend/invoice_backend.py \
    src/backend/database_backend.py \
    src/backend/settings_backend.py \
    src/models/__init__.py \
    src/utils/__init__.py \
    src/ui/__init__.py \
    resources/qml/desktop/main.qml \
    resources/qml/desktop/InvoicePage.qml \
    resources/qml/desktop/DatabasePage.qml \
    resources/qml/desktop/SettingsPage.qml \
    resources/qml/desktop/qmldir \
    resources/qml/mobile/main.qml \
    resources/qml/mobile/InvoicePage.qml \
    resources/qml/mobile/DatabasePage.qml \
    resources/qml/mobile/SettingsPage.qml \
    resources/qml/mobile/qmldir \
    tests/__init__.py \
    tests/test_backends.py

# Helper target for Qt Creator (no C++ compilation)
all: force
	@echo "WorkOrder: Python/PyQt6 project"
	@echo "Configure: cmake --preset workorder"
	@echo "Run:       cmake --build build --target run"
	@echo "Or:        python src/main.py --type $$BUILD_TYPE"

force:
