# Application data paths

WorkOrder stores runtime data in an OS sandbox (same idea as
`DapWalletPathDefines` / `WalletStorage` in cellframe-wallet).
Linux does **not** use `/opt` — only user/app writable locations.

## Class

| File | Role |
|------|------|
| `cpp/utils/WorkOrderPathDefines.h/.cpp` | Per-OS storage root + subpaths |
| `cpp/utils/AppPaths.h/.cpp` | Runtime API (`createPaths`, `dbDir`, …) |

`ApplicationBootstrap::setupEnvironment()` calls `AppPaths::createPaths()` before logging.

## Layout

```
{STORAGE}/
  data/
    log/       # rotating WorkOrder_DD-MM-YYYY.log
    db/        # *.db (clients, services, objects)
    config/    # WorkOrder.conf (QSettings Ini), app_settings.json
```

Reports are **not** under `{STORAGE}/data`. Default folder is
user Documents (`QStandardPaths::DocumentsLocation`, or `WORKORDER_REPORTS_DIR`).
Save dialogs use the path chosen by the user.

## STORAGE by OS

Resolved at compile time via `#if defined(Q_OS_*)` in `WorkOrderPathDefines.cpp`:

| OS | Path |
|----|------|
| **Android** (`Q_OS_ANDROID`) | `QStandardPaths::AppDataLocation` (app sandbox) |
| **Windows** (`Q_OS_WIN`) | `%APPDATA%\WorkOrderApp\WorkOrder` |
| **macOS** (`Q_OS_MACOS`) | `~/Library/Application Support/WorkOrderApp/WorkOrder` |
| **Linux** (`Q_OS_LINUX`) | `~/.local/share/WorkOrderApp/WorkOrder` |

Org/app names: `WorkOrderApp` / `WorkOrder` (set before path resolve).

`AppPaths::isAndroidRuntime()` is separate — runtime UI/bootstrap helper, not used for storage roots.

## Opening / sharing logs and DB folders in Settings

Desktop / Windows / Linux / macOS: `openLogDirectory()` / `openDbDirectory()` open
`logDir` / `dbDir` in the file manager.

Android: only `copyLogs()` — packs `logDir` into `logs.zip` and shares via
`Intent.ACTION_SEND` (`com.workorder.LogShare` + FileProvider). Catalog buttons
are hidden.

## Overrides

| Env | Meaning |
|-----|---------|
| `WORKORDER_DATA_DIR` | Replace `{STORAGE}` root |
| `WORKORDER_REPORTS_DIR` | Replace default reports folder |

## QSettings

`QSettingsStore` writes Ini file:

`{STORAGE}/data/config/WorkOrder.conf`

(not native registry / `~/.config`).

## API map

| Method | Path |
|--------|------|
| `WorkOrderPathDefines::storagePath()` / `AppPaths::storageDir()` | `{STORAGE}` |
| `::dataPath()` / `dataDir()` | `{STORAGE}/data` |
| `::logPath()` / `logDir()` | `data/log` |
| `::dbPath()` / `dbDir()` | `data/db` |
| `::configPath()` / `configDir()` | `data/config` |
| `::reportsPath()` | Documents (or env) |
| `::configFilePath()` | `data/config/WorkOrder.conf` |
