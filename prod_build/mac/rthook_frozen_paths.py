"""PyInstaller runtime hook: fix resource paths in frozen WorkOrder.app."""
from __future__ import annotations

import sys
from pathlib import Path


def _patch_app_paths() -> None:
    base = Path(getattr(sys, "_MEIPASS", ""))
    if not base.is_dir():
        return

    import app_paths

    app_paths.PROJECT_ROOT = base
    app_paths.RESOURCES_DIR = base / "resources"
    app_paths.QML_ROOT = app_paths.RESOURCES_DIR / "qml"
    app_paths.ICONS_DIR = app_paths.RESOURCES_DIR / "icons" / "appIcons"


if getattr(sys, "frozen", False):
    _patch_app_paths()
