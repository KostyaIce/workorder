"""Qt bindings compatibility layer: PySide6 (Android) or PyQt6 (desktop)."""
from __future__ import annotations

from pathlib import Path

try:
    from PySide6.QtCore import (
        QAbstractListModel,
        QCoreApplication,
        QModelIndex,
        QObject,
        QSettings,
        QSortFilterProxyModel,
        QStandardPaths,
        QSysInfo,
        QTimer,
        Qt,
        QUrl,
        QtMsgType,
        Property as pyqtProperty,
        Signal as pyqtSignal,
        Slot as pyqtSlot,
        qInstallMessageHandler,
    )
    from PySide6.QtGui import (
        QColor,
        QDesktopServices,
        QFont,
        QFontDatabase,
        QGuiApplication,
        QIcon,
        QPalette,
    )
    from PySide6.QtQml import QQmlApplicationEngine, QQmlContext
    from PySide6.QtQuick import QQuickWindow

    import PySide6

    QT_BINDING = "PySide6"
    _QT_PACKAGE = PySide6
except ImportError:
    from PyQt6.QtCore import (
        QAbstractListModel,
        QCoreApplication,
        QModelIndex,
        QObject,
        QSettings,
        QSortFilterProxyModel,
        QStandardPaths,
        QSysInfo,
        QTimer,
        Qt,
        QUrl,
        QtMsgType,
        pyqtProperty,
        pyqtSignal,
        pyqtSlot,
        qInstallMessageHandler,
    )
    from PyQt6.QtGui import (
        QColor,
        QDesktopServices,
        QFont,
        QFontDatabase,
        QGuiApplication,
        QIcon,
        QPalette,
    )
    from PyQt6.QtQml import QQmlApplicationEngine, QQmlContext
    from PyQt6.QtQuick import QQuickWindow

    import PyQt6

    QT_BINDING = "PyQt6"
    _QT_PACKAGE = PyQt6


def qt_qml_path() -> Path:
    return Path(_QT_PACKAGE.__file__).resolve().parent / "Qt6" / "qml"
