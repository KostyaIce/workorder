"""Runtime paths for WorkOrder (PyCharm, Qt Creator, CMake, plain python, Android)."""
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

_DATA_DIR: Path | None = None


def setup_runtime() -> None:
    """Ensure src and optional CMake build config are on sys.path."""
    _prepend_path(str(SRC_DIR))

    build_dir = os.environ.get("WORKORDER_BUILD_DIR")
    if build_dir:
        _prepend_path(build_dir)


def _prepend_path(path: str) -> None:
    if path and path not in sys.path:
        sys.path.insert(0, path)


def is_android_runtime() -> bool:
    if os.environ.get("ANDROID_ARGUMENT") is not None:
        return True
    if os.environ.get("WORKORDER_PLATFORM") == "android":
        return True

    try:
        from qt_compat import QSysInfo

        return QSysInfo.productType().lower() == "android"
    except Exception:
        return False


def _qt_standard_paths():
    from qt_compat import QStandardPaths

    return QStandardPaths


def data_dir() -> Path:
    """Writable application data directory."""
    global _DATA_DIR
    if _DATA_DIR is not None:
        return _DATA_DIR

    if is_android_runtime():
        QStandardPaths = _qt_standard_paths()
        base = QStandardPaths.writableLocation(
            QStandardPaths.StandardLocation.AppDataLocation
        )
        if not base:
            base = QStandardPaths.writableLocation(
                QStandardPaths.StandardLocation.GenericDataLocation
            )
        if not base:
            private = os.environ.get("ANDROID_PRIVATE")
            if private:
                base = private
        if not base:
            app_path = os.environ.get("ANDROID_APP_PATH")
            if app_path:
                base = app_path
        path = Path(base) / "data" if base else PROJECT_ROOT / "data"
    else:
        override = os.environ.get("WORKORDER_DATA_DIR")
        path = Path(override).expanduser() if override else PROJECT_ROOT / "data"

    path.mkdir(parents=True, exist_ok=True)
    _DATA_DIR = path.resolve()
    return _DATA_DIR


def project_data_dir() -> Path:
    """Backward-compatible alias for data_dir()."""
    return data_dir()


def default_app_type() -> str:
    if is_android_runtime():
        return "mobile"
    return "desktop"


def _cli_type_explicitly_provided() -> bool:
    return "--type" in sys.argv


def resolve_app_type(cli_type: str) -> str:
    if is_android_runtime():
        return "mobile"

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
    if is_android_runtime():
        path = ICONS_DIR / "icon_linux.png"
    elif sys.platform == "darwin":
        path = ICONS_DIR / "icon_macos.icns"
    elif sys.platform == "win32":
        path = ICONS_DIR / "icon_win32.ico"
    else:
        path = ICONS_DIR / "icon_linux.png"
    return path if path.is_file() else None
