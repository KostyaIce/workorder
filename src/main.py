#!/usr/bin/env python3
"""
WorkOrder Application
Главный файл запуска приложения
"""

import sys
import os
import logging
import argparse
from pathlib import Path

# Bootstrap before local imports (PyCharm, Qt Creator, CMake run target)
_src_dir = Path(__file__).resolve().parent
if str(_src_dir) not in sys.path:
    sys.path.insert(0, str(_src_dir))

from app_paths import (
    setup_runtime,
    resolve_app_type,
    qml_main_path,
    qml_import_paths,
    application_icon_path,
    UI_FONT_PATH,
)

setup_runtime()

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger("workorder")

# Non-native style: Basic on macOS (custom button backgrounds), Fusion elsewhere.
if sys.platform == "darwin":
    os.environ.setdefault("QT_QUICK_CONTROLS_STYLE", "Basic")
else:
    os.environ.setdefault("QT_QUICK_CONTROLS_STYLE", "Fusion")

import PyQt6

from PyQt6.QtCore import QUrl, Qt
from PyQt6.QtGui import QColor, QFont, QFontDatabase, QGuiApplication, QIcon, QPalette
from PyQt6.QtQml import QQmlApplicationEngine, QQmlContext
from PyQt6.QtQuick import QQuickWindow

from backend.invoice_backend import InvoiceBackend
from backend.database_backend import DatabaseBackend
from backend.report_options_backend import ReportOptionsBackend
from backend.settings_backend import SettingsBackend
from backend.report_backend import ReportBackend


def _setup_light_palette(app: QGuiApplication) -> None:
    palette = QPalette()
    palette.setColor(QPalette.ColorRole.Window, QColor("#F5F5F5"))
    palette.setColor(QPalette.ColorRole.WindowText, QColor("#212121"))
    palette.setColor(QPalette.ColorRole.Base, QColor("#FFFFFF"))
    palette.setColor(QPalette.ColorRole.AlternateBase, QColor("#F5F5F5"))
    palette.setColor(QPalette.ColorRole.Text, QColor("#212121"))
    palette.setColor(QPalette.ColorRole.Button, QColor("#FFFFFF"))
    palette.setColor(QPalette.ColorRole.ButtonText, QColor("#212121"))
    palette.setColor(QPalette.ColorRole.Highlight, QColor("#2196F3"))
    palette.setColor(QPalette.ColorRole.HighlightedText, QColor("#FFFFFF"))
    palette.setColor(QPalette.ColorRole.Mid, QColor("#E0E0E0"))
    palette.setColor(QPalette.ColorRole.Dark, QColor("#757575"))
    palette.setColor(QPalette.ColorRole.Light, QColor("#FFFFFF"))
    palette.setColor(QPalette.ColorRole.Shadow, QColor("#BDBDBD"))
    app.setPalette(palette)


def _setup_ui_font(app: QGuiApplication) -> str | None:
    if sys.platform != "linux":
        return None

    if not UI_FONT_PATH.is_file():
        logger.warning("UI font not found: %s", UI_FONT_PATH)
        return None

    font_id = QFontDatabase.addApplicationFont(str(UI_FONT_PATH))
    if font_id < 0:
        logger.warning("Failed to load UI font: %s", UI_FONT_PATH)
        return None

    families = QFontDatabase.applicationFontFamilies(font_id)
    if not families:
        return None

    family = families[0]
    font = app.font()
    font.setFamily(family)
    if font.pixelSize() <= 0 and font.pointSize() > 0:
        font.setPixelSize(int(font.pointSize() * 96 / 72))
    app.setFont(font)
    logger.info("UI font: %s", family)
    return family


def _apply_window_icons(app: QGuiApplication, engine: QQmlApplicationEngine) -> None:
    icon = app.windowIcon()
    if icon.isNull():
        return

    for root in engine.rootObjects():
        if isinstance(root, QQuickWindow):
            root.setIcon(icon)


def main():
    parser = argparse.ArgumentParser(description='WorkOrder Application')
    parser.add_argument('--type', choices=['mobile', 'desktop'], default='desktop',
                        help='Тип приложения: mobile или desktop')
    args = parser.parse_args()

    app_type = resolve_app_type(args.type)
    logger.info("Starting WorkOrder, type=%s", app_type)
    # Включаем атрибуты для правильного масштабирования
    QGuiApplication.setHighDpiScaleFactorRoundingPolicy(
        Qt.HighDpiScaleFactorRoundingPolicy.PassThrough
    )

    app = QGuiApplication(sys.argv)
    app.setApplicationName("WorkOrder")
    app.setOrganizationName("WorkOrderApp")

    _setup_light_palette(app)
    ui_font_family = _setup_ui_font(app)

    icon_path = application_icon_path()
    if icon_path is not None:
        icon = QIcon(str(icon_path))
        if not icon.isNull():
            app.setWindowIcon(icon)
            if sys.platform == "darwin":
                from macos_icon import set_dock_icon
                set_dock_icon(str(icon_path))

    engine = QQmlApplicationEngine()

    qt_qml_path = Path(PyQt6.__file__).resolve().parent / "Qt6" / "qml"
    engine.addImportPath(str(qt_qml_path))
    for import_path in qml_import_paths(app_type):
        engine.addImportPath(import_path)

    # Создаем бэкенды
    invoice_backend = InvoiceBackend(engine)
    database_backend = DatabaseBackend()
    settings_backend = SettingsBackend()
    report_options_backend = ReportOptionsBackend()
    report_backend = ReportBackend(settings_backend, report_options_backend, engine)
    report_backend.initializeData()
    invoice_backend.bind_report_backend(report_backend)

    # Регистрируем бэкенды в QML
    context = engine.rootContext()
    context.setContextProperty("invoiceBackend", invoice_backend)
    context.setContextProperty("databaseBackend", database_backend)
    context.setContextProperty("settingsBackend", settings_backend)
    context.setContextProperty("reportOptionsBackend", report_options_backend)
    context.setContextProperty("reportBackend", report_backend)

    # Устанавливаем тип приложения как свойство
    context.setContextProperty("appType", app_type)
    if ui_font_family:
        context.setContextProperty("defaultFontFamily", ui_font_family)

    qml_path = qml_main_path(app_type)
    engine.load(QUrl.fromLocalFile(str(qml_path)))

    if not engine.rootObjects():
        logger.error("Failed to load QML: %s", qml_path)
        sys.exit(-1)

    _apply_window_icons(app, engine)

    sys.exit(app.exec())


if __name__ == "__main__":
    main()
