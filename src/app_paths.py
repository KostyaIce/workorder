"""Runtime paths for WorkOrder (PyCharm, Qt Creator, CMake, plain python)."""
from __future__ import annotations

import os
import sys
from pathlib import Path

_SRC_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = _SRC_DIR.parent
SRC_DIR = _SRC_DIR
RESOURCES_DIR = PROJECT_ROOT / "resources"
QML_ROOT = RESOURCES_DIR / "qml"
ICONS_DIR = RESOURCES_DIR / "icons" / "appIcons"
FONTS_DIR = RESOURCES_DIR / "fonts"
UI_FONT_PATH = FONTS_DIR / "DejaVuSans.ttf"


def setup_runtime() -> None:
    """Ensure src and optional CMake build config are on sys.path."""
    _prepend_path(str(SRC_DIR))

    build_dir = os.environ.get("WORKORDER_BUILD_DIR")
    if build_dir:
        _prepend_path(build_dir)


def _prepend_path(path: str) -> None:
    if path and path not in sys.path:
        sys.path.insert(0, path)


def _cli_type_explicitly_provided() -> bool:
    return "--type" in sys.argv


def resolve_app_type(cli_type: str) -> str:
    env_type = os.environ.get("WORKORDER_APP_TYPE")
    if env_type in ("mobile", "desktop"):
        return env_type

    if _cli_type_explicitly_provided() and cli_type in ("mobile", "desktop"):
        return cli_type

    try:
        from workorder_config import APP_TYPE
        if APP_TYPE in ("mobile", "desktop"):
            return APP_TYPE
    except ImportError:
        pass
    return cli_type


def qml_main_path(app_type: str) -> Path:
    return QML_ROOT / app_type / "main.qml"


def qml_import_paths(app_type: str) -> list[str]:
    paths = [str(QML_ROOT), str(QML_ROOT / app_type)]
    extra = os.environ.get("QML_IMPORT_PATH")
    if extra:
        paths.extend(p for p in extra.split(os.pathsep) if p)
    return paths


def application_icon_path() -> Path | None:
    if sys.platform == "darwin":
        path = ICONS_DIR / "icon_macos.icns"
    elif sys.platform == "win32":
        path = ICONS_DIR / "icon_win32.ico"
    else:
        path = ICONS_DIR / "icon_linux.png"
    return path if path.is_file() else None
