# Application versioning

Single source of truth: [`version.mk`](../version.mk) at the repository root.

```
VERSION_MAJOR=1
VERSION_MINOR=0
VERSION_PATCH=0
```

## How it is used

| Consumer | Format |
|----------|--------|
| CMake `WORKORDER_VERSION` / `project(VERSION …)` | `MAJOR.MINOR.PATCH` |
| C++ (global `add_compile_definitions`) / Settings UI | `MAJOR.MINOR.PATCH` |
| Python `app_version.get_version()` | `MAJOR.MINOR.PATCH` |
| Android `versionName` (`WORKORDER_VERSION_NAME`) | `MAJOR.MINOR-PATCH` |
| Android `versionCode` (`WORKORDER_VERSION_CODE`) | `Mmmmpp` (e.g. `1.0.12` → `100012`) |

CMake loads `version.mk` once via `cmake/WorkOrderVersion.cmake` and sets global variables
`WORKORDER_VERSION`, `WORKORDER_VERSION_NAME`, `WORKORDER_VERSION_CODE` for the whole project.
## Automatic patch bump (Git hook)

On each commit, the pre-commit hook increments `VERSION_PATCH` and syncs `cpp/android/AndroidManifest.xml`.

Install once per clone:

```bash
bash utils/hooks/setup-hooks.sh
# or
python3 utils/hooks/install.py
```

Manual major/minor bumps: edit `version.mk` and commit (patch still auto-increments on that commit).

To skip the bump for a single commit: `git commit --no-verify` (not recommended for release commits).
