# Logging

WorkOrder uses the same approach as **DapLogger** in dapchainvpn-client GUI:
install `qInstallMessageHandler` once at startup, then use normal Qt logging APIs in code.

## Rule

In C++ and QML-related code use:

```cpp
qInfo("...");
qWarning("...");
qDebug() << "...";
```

Do **not** introduce a parallel logger API or wrappers that bypass Qt.

## C++

`AppLogging::setupAppLogging()` (from `ApplicationBootstrap::setupEnvironment`):

1. Applies `QLoggingCategory` filter rules from CMake (`cmake/WorkOrderLogging.cmake`)
2. Opens rotating file `data/log/WorkOrder_DD-MM-YYYY.log` under app storage
3. Calls `qInstallMessageHandler(...)`

Sink: stderr (or Android logcat) + log file.

Helpers: `AppLogging::pathToLog()`, `AppLogging::pathToFile()`.

See [app-paths.md](app-paths.md) for the full storage layout.

### CMake (client / debug builds)

| Variable | Meaning |
|----------|---------|
| `WORKORDER_QT_LOGGING_VERBOSE=OFF` | Default: mute `qt.*.debug` / `qt.*.info` (no `qt.qml.import` spam) |
| `WORKORDER_QT_LOGGING_VERBOSE=ON` | Keep Qt framework debug/info for client debugging |
| `WORKORDER_QT_LOGGING_RULES=...` | Full custom rules string (overrides VERBOSE preset) |

Examples:

```bash
# Quiet (default)
cmake --preset cpp

# Verbose Qt categories for a client build
cmake --preset cpp-logging-verbose
# or
cmake -S cpp -B build/cpp -DWORKORDER_QT_LOGGING_VERBOSE=ON

# Fully custom rules
cmake -DWORKORDER_QT_LOGGING_RULES="*.debug=true
qt.qml.binding.debug=true
qt.*.debug=false" ...
```

### Runtime (no rebuild)

```bash
export QT_LOGGING_RULES='*.debug=true
qt.qml.import.debug=true'
./WorkOrder
```

Environment `QT_LOGGING_RULES` overrides the rules baked in at configure time.

## Python

`utils.app_logging.setup_app_logging()` installs the same Qt message handler and mirrors
`logging.getLogger(...)` into that sink (one file, one format).

## Cloud disk

`CloudDiskBackend` logs with `qInfo` / `qWarning` — they go through `AppLogging` automatically.
