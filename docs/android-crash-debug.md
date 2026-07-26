# Android: отладка и логи

## Logcat (adb)

```bash
chmod +x scripts/android/logcat_workorder.sh
./scripts/android/logcat_workorder.sh
```

Запустите WorkOrder на устройстве. В терминале должны появиться строки с префиксом `[workorder]` (Python/Qt/QML через `console.log`).

Если приложение уже запущено, скрипт фильтрует logcat по PID процесса `com.workorder.workorder`.

Сохранить logcat в файл:

```bash
adb logcat -d > /tmp/workorder-crash.log
grep -iE '\[workorder\]|python|Qt:|Traceback|FATAL|Error|com\.workorder' /tmp/workorder-crash.log
```

## Файл лога на устройстве

На Android приложение пишет лог в `AppPaths::logDir()` (`…/data/log/WorkOrder_DD-MM-YYYY.log` внутри sandbox).

Просмотр:

```bash
adb shell run-as com.workorder.workorder find files -name 'WorkOrder_*.log'
adb shell run-as com.workorder.workorder find files -path '*/data/log/*' -name '*.log'
```

См. [app-paths.md](app-paths.md).

## Типичные причины

| Симптом | Что проверить |
|---------|---------------|
| `ModuleNotFoundError: No module named 'PIL'` | В APK нет Pillow. Пересборка: `P4A_CLEAN=1 ./scripts/android/build_apk.sh` |
| `Failed to load QML` | Путь к `resources/qml/mobile/main.qml`, import `WorkOrder.Common` |
| `Backend initialization failed` | SQLite / `AppPaths::dbDir()` — права на запись |
| `Qt Quick: ...` | Стиль Controls — на Android используется `Basic`, не `Fusion` |
| Пустой logcat, но app работает | Смотреть `data/log/WorkOrder_*.log`; в logcat — `--pid=$(adb shell pidof com.workorder.workorder)` |
| `adb devices` пустой | USB-отладка, кабель, разрешение на устройстве |

## Пересборка после правок

```bash
./scripts/android/build_apk.sh
adb install -r WorkOrder*.apk
```
