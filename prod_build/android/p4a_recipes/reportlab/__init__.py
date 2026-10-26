# WorkOrder p4a recipe: reportlab 4.2.5 from pure-Python wheels (platypus PDF).
from __future__ import annotations

import glob
import os
import shutil

from pythonforandroid.logger import info, shprint
from pythonforandroid.recipe import PythonRecipe


class ReportlabRecipe(PythonRecipe):
    version = "4.2.5"
    call_hostpython_via_targetpython = False
    install_in_hostpython = False
    hostpython_prerequisites = []
    depends = ["Pillow"]

    def build_arch(self, arch):
        info("Installing reportlab {} from pure-Python wheels".format(self.version))
        env = self.get_recipe_env(arch)
        target = self.ctx.get_python_install_dir(arch.arch)
        for path in glob.glob(os.path.join(target, "reportlab*")):
            if os.path.isdir(path):
                shutil.rmtree(path)
            elif os.path.isfile(path):
                os.remove(path)
        shprint(
            self._host_recipe.pip,
            "install",
            "--force-reinstall",
            "reportlab=={}".format(self.version),
            "chardet",
            "--no-deps",
            "--only-binary",
            ":all:",
            "--target",
            target,
            _env=env,
        )


recipe = ReportlabRecipe()
