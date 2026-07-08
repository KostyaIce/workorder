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

## Файл debug.log на устройстве

На Android приложение пишет полный лог в `data_dir()/debug.log` (обычно `files/data/debug.log` внутри sandbox).

Просмотр в реальном времени:

```bash
adb shell run-as com.workorder.workorder tail -f files/data/debug.log
```

Сохранить на ПК:

```bash
adb shell run-as com.workorder.workorder cat files/data/debug.log > /tmp/workorder-debug.log
```

Если путь другой:

```bash
adb shell run-as com.workorder.workorder find . -name debug.log
```

## Типичные причины

| Симптом | Что проверить |
|---------|---------------|
| `ModuleNotFoundError: No module named 'PIL'` | В APK нет Pillow. Пересборка: `P4A_CLEAN=1 ./scripts/android/build_apk.sh` |
| `Failed to load QML` | Путь к `resources/qml/mobile/main.qml`, import `WorkOrder.Common` |
| `Backend initialization failed` | SQLite / `data_dir()` — права на запись |
| `Qt Quick: ...` | Стиль Controls — на Android используется `Basic`, не `Fusion` |
| Пустой logcat, но app работает | Смотреть `files/data/debug.log`; в logcat — `--pid=$(adb shell pidof com.workorder.workorder)` |
| `adb devices` пустой | USB-отладка, кабель, разрешение на устройстве |

## Пересборка после правок

```bash
./scripts/android/build_apk.sh
adb install -r WorkOrder*.apk
```
