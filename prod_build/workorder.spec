# -*- mode: python ; coding: utf-8 -*-
"""PyInstaller spec for WorkOrder macOS release bundle."""
import os
from pathlib import Path

from PyInstaller.utils.hooks import collect_all

SPEC_DIR = Path(SPECPATH)
PROJECT_ROOT = SPEC_DIR.parent
WORK_DIR = SPEC_DIR / "work"
ICON_PATH = PROJECT_ROOT / "resources" / "icons" / "appIcons" / "icon_macos.icns"

APP_TYPE = os.environ.get("WORKORDER_APP_TYPE", "desktop")
VERSION = os.environ.get("WORKORDER_VERSION", "1.0.0")

if APP_TYPE not in ("desktop", "mobile"):
    raise SystemExit(f"WORKORDER_APP_TYPE must be desktop or mobile, got: {APP_TYPE!r}")

WORK_DIR.mkdir(parents=True, exist_ok=True)
(WORK_DIR / "workorder_config.py").write_text(f"APP_TYPE = '{APP_TYPE}'\n", encoding="utf-8")

block_cipher = None

pyqt6_datas, pyqt6_binaries, pyqt6_hiddenimports = collect_all("PyQt6")
openpyxl_datas, openpyxl_binaries, openpyxl_hiddenimports = collect_all("openpyxl")

a = Analysis(
    [str(PROJECT_ROOT / "src" / "main.py")],
    pathex=[str(PROJECT_ROOT / "src"), str(WORK_DIR)],
    binaries=[*pyqt6_binaries, *openpyxl_binaries],
    datas=[
        (str(PROJECT_ROOT / "resources"), "resources"),
        *pyqt6_datas,
        *openpyxl_datas,
    ],
    hiddenimports=[
        *pyqt6_hiddenimports,
        *openpyxl_hiddenimports,
        "reportlab",
        "reportlab.lib",
        "reportlab.pdfgen",
        "reportlab.platypus",
        "openpyxl",
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[str(SPEC_DIR / "rthook_frozen_paths.py")],
    excludes=[],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name="WorkOrder",
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)

coll = COLLECT(
    exe,
    a.binaries,
    a.datas,
    strip=False,
    upx=True,
    upx_exclude=[],
    name="WorkOrder",
)

app = BUNDLE(
    coll,
    name="WorkOrder.app",
    icon=str(ICON_PATH) if ICON_PATH.is_file() else None,
    bundle_identifier="com.workorder.app",
    info_plist={
        "CFBundleShortVersionString": VERSION,
        "CFBundleVersion": VERSION,
        "CFBundleName": "WorkOrder",
        "CFBundleDisplayName": "WorkOrder",
        "NSHighResolutionCapable": True,
        "LSMinimumSystemVersion": "11.0",
    },
)
