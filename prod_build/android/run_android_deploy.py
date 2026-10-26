#!/usr/bin/env python3
"""WorkOrder wrapper for pyside6-android-deploy (buildozer spec fixes)."""
from __future__ import annotations

import os
import runpy
import sys
from pathlib import Path

P4A_PYTHON_VERSION = os.environ.get("P4A_PYTHON_VERSION", "3.11.11")
P4A_RECIPES_DIR = Path(__file__).resolve().parent / "p4a_recipes"

# QtLoader loads native libs in list order; Core must come before Quick/Qml.
QT_MODULE_LOAD_ORDER = (
    "Core",
    "Concurrent",
    "Network",
    "Gui",
    "Qml",
    "OpenGL",
    "QuickControls2",
    "Quick",
    "Widgets",
    "Sql",
    "Svg",
    "Xml",
)


def sort_qt_modules(modules: list[str]) -> list[str]:
    rank = {name: idx for idx, name in enumerate(QT_MODULE_LOAD_ORDER)}
    return sorted(dict.fromkeys(modules), key=lambda name: rank.get(name, 1000))


def pyside_scripts_dir() -> Path:
    import PySide6

    return Path(PySide6.__file__).resolve().parent / "scripts"


def patch_android_config():
    scripts_dir = pyside_scripts_dir()
    if str(scripts_dir) not in sys.path:
        sys.path.insert(0, str(scripts_dir))

    import shutil

    from deploy_lib.android import android_config as ac

    original_find = ac.AndroidConfig.find_recipe_dir

    def patched_find(self):
        recipe_dir = original_find(self)
        if recipe_dir and not self.dry_run and P4A_RECIPES_DIR.is_dir():
            dst_root = Path(recipe_dir)
            for src in P4A_RECIPES_DIR.iterdir():
                if not src.is_dir():
                    continue
                dst = dst_root / src.name
                shutil.copytree(src, dst, dirs_exist_ok=True)
        return recipe_dir

    ac.AndroidConfig.find_recipe_dir = patched_find


def patch_buildozer_config():
    scripts_dir = pyside_scripts_dir()
    if str(scripts_dir) not in sys.path:
        sys.path.insert(0, str(scripts_dir))

    from deploy_lib.android import buildozer as bz

    original_init = bz.BuildozerConfig.__init__

    def patched_init(self, buildozer_spec_file, pysidedeploy_config):
        pysidedeploy_config.modules = sort_qt_modules(pysidedeploy_config.modules)
        original_init(self, buildozer_spec_file, pysidedeploy_config)
        requirements = (
            f"python3=={P4A_PYTHON_VERSION},shiboken6,PySide6,"
            "Pillow,reportlab,chardet,openpyxl,et_xmlfile"
        )
        self.set_value("app", "requirements", requirements)
        self.set_value("app", "source.dir", ".")
        self.set_value("app", "package.domain", "com.workorder")
        include_exts = self.get_value("app", "source.include_exts")
        if include_exts:
            for ext in ("ttf", "json"):
                if ext not in include_exts.split(","):
                    include_exts = f"{include_exts},{ext}"
            self.set_value("app", "source.include_exts", include_exts, raise_warning=False)
        perms = self.get_value("app", "android.permissions") or ""
        perm_set = {p.strip() for p in perms.split(",") if p.strip()}
        perm_set.update(
            {
                "android.permission.READ_EXTERNAL_STORAGE",
                "android.permission.WRITE_EXTERNAL_STORAGE",
            }
        )
        self.set_value("app", "android.permissions", ",".join(sorted(perm_set)))
        self.update_config()

    bz.BuildozerConfig.__init__ = patched_init


if __name__ == "__main__":
    os.environ.setdefault("VERSION_python3", P4A_PYTHON_VERSION)
    os.environ.setdefault("VERSION_hostpython3", P4A_PYTHON_VERSION)
    patch_buildozer_config()
    patch_android_config()
    deploy_script = pyside_scripts_dir() / "android_deploy.py"
    runpy.run_path(str(deploy_script), run_name="__main__")
