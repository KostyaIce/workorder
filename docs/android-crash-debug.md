# Android: отладка и логи

## Logcat (adb)

```bash
chmod +x prod_build/android/logcat_workorder.sh
./prod_build/android/logcat_workorder.sh
```

Запустите WorkOrder на устройстве. В терминале должны появиться строки с префиксом `[workorder]` (Python/Qt/QML через `console.log`).

Если приложение уже запущено, скрипт фильтрует logcat по PID процесса `com.konstantin.workorder`.

Сохранить logcat в файл:

```bash
adb logcat -d > /tmp/workorder-crash.log
grep -iE '\[workorder\]|python|Qt:|Traceback|FATAL|Error|com\.konstantin\.workorder' /tmp/workorder-crash.log
```

## Файл лога на устройстве

На Android приложение пишет лог в `AppPaths::logDir()` (`…/data/log/WorkOrder_DD-MM-YYYY.log` внутри sandbox).

Просмотр:

```bash
adb shell run-as com.konstantin.workorder find files -name 'WorkOrder_*.log'
adb shell run-as com.konstantin.workorder find files -path '*/data/log/*' -name '*.log'
```

См. [app-paths.md](app-paths.md).

## Типичные причины

| Симптом | Что проверить |
|---------|---------------|
| `ModuleNotFoundError: No module named 'PIL'` | В APK нет Pillow. Пересборка: `P4A_CLEAN=1 ./prod_build/android/build_apk.sh` |
| `Failed to load QML` | Путь к `resources/qml/mobile/main.qml`, import `WorkOrder.Common` |
| `Backend initialization failed` | SQLite / `AppPaths::dbDir()` — права на запись |
| `Qt Quick: ...` | Стиль Controls — на Android используется `Basic`, не `Fusion` |
| Пустой logcat, но app работает | Смотреть `data/log/WorkOrder_*.log`; в logcat — `--pid=$(adb shell pidof com.konstantin.workorder)` |
| `adb devices` пустой | USB-отладка, кабель, разрешение на устройстве |

## Пересборка после правок

```bash
./prod_build/android/build_apk.sh
adb install -r WorkOrder*.apk
```
