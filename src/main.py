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

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger("workorder")

# Non-native style required for custom Button backgrounds on macOS
os.environ.setdefault("QT_QUICK_CONTROLS_STYLE", "Basic")

# Добавляем путь к src для импортов
sys.path.insert(0, str(Path(__file__).parent))

from PyQt6.QtCore import QUrl, Qt
from PyQt6.QtGui import QGuiApplication
from PyQt6.QtQml import QQmlApplicationEngine, QQmlContext

from backend.invoice_backend import InvoiceBackend
from backend.database_backend import DatabaseBackend
from backend.settings_backend import SettingsBackend
from backend.report_backend import ReportBackend


def _resolve_app_type(cli_type):
    """Resolve UI type: CMake build config overrides CLI default."""
    try:
        from workorder_config import APP_TYPE
        if APP_TYPE in ('mobile', 'desktop'):
            return APP_TYPE
    except ImportError:
        pass
    return cli_type


def main():
    parser = argparse.ArgumentParser(description='WorkOrder Application')
    parser.add_argument('--type', choices=['mobile', 'desktop'], default='desktop',
                        help='Тип приложения: mobile или desktop')
    args = parser.parse_args()

    app_type = _resolve_app_type(args.type)
    logger.info("Starting WorkOrder, type=%s", app_type)
    # Включаем атрибуты для правильного масштабирования
    QGuiApplication.setHighDpiScaleFactorRoundingPolicy(
        Qt.HighDpiScaleFactorRoundingPolicy.PassThrough
    )
    
    app = QGuiApplication(sys.argv)
    app.setApplicationName("WorkOrder")
    app.setOrganizationName("WorkOrderApp")
    
    engine = QQmlApplicationEngine()
    
    # Создаем бэкенды
    invoice_backend = InvoiceBackend()
    database_backend = DatabaseBackend()
    settings_backend = SettingsBackend()
    report_backend = ReportBackend(settings_backend, engine)
    report_backend.initializeData()
    invoice_backend.bind_report_backend(report_backend)

    def sync_invoice_services():
        invoice_backend.setServicesCatalog(database_backend.getAllServices())

    # def sync_invoice_client(client_id, name, kind):
    #     invoice_backend.setCurrentClient(client_id, name, kind)

    database_backend.servicesChanged.connect(sync_invoice_services)
    # report_backend.clientSelected.connect(sync_invoice_client)
    sync_invoice_services()
    
    # Регистрируем бэкенды в QML
    context = engine.rootContext()
    context.setContextProperty("invoiceBackend", invoice_backend)
    context.setContextProperty("databaseBackend", database_backend)
    context.setContextProperty("settingsBackend", settings_backend)
    context.setContextProperty("reportBackend", report_backend)
    
    # Устанавливаем тип приложения как свойство
    context.setContextProperty("appType", app_type)
    
    # Load QML: skin-specific pages + shared WorkOrder.Common module
    base_path = Path(__file__).parent.parent
    engine.addImportPath(str(base_path / "resources" / "qml"))

    if app_type == "mobile":
        qml_path = base_path / "resources" / "qml" / "mobile" / "main.qml"
    else:
        qml_path = base_path / "resources" / "qml" / "desktop" / "main.qml"
    
    engine.load(QUrl.fromLocalFile(str(qml_path)))
    
    if not engine.rootObjects():
        logger.error("Failed to load QML: %s", qml_path)
        sys.exit(-1)
    
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
