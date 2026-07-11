# WorkOrder C++ на Android

Сборка **compact/mobile UI** через Qt 6 CMake Kit и `androiddeployqt`.

Python APK (`android/pysidedeploy.spec`) — отдельный путь. Здесь только **C++** (`cpp/`).

## Требования

| Компонент | Путь (пример) |
|-----------|----------------|
| Qt 6.8 Android arm64 | `~/Qt/6.8.3/android_arm64_v8a` |
| Qt host tools | `~/Qt/6.8.3/gcc_64` |
| Android SDK | `~/Android/Sdk` |
| NDK | `~/Android/Sdk/ndk/26.1.10909125` |
| JDK | 17 |

Установить через **Qt Maintenance Tool**: Qt for Android + нужный NDK.

## Qt Creator

1. **File → Open** → `cpp/CMakeLists.txt`
2. Kit: **Android Qt 6.8.3 Clang arm64-v8a** (не Desktop GCC)
3. **Configure Project**
4. В логе CMake: `Android target configured: compact mobile UI`
5. **Run** (▶) — Creator соберёт APK и установит на устройство/эмулятор

Run target для APK: **`WorkOrder_make_apk`** или **`run-android-apk`**.

На Android всегда **mobile UI** (`Type=mobile`, аргумент `--type mobile` в манифесте).

## CMake Preset (терминал)

```bash
cmake --preset cpp-android-arm64
cmake --build build/cpp-android-arm64 --target WorkOrder_make_apk
adb install -r build/cpp-android-arm64/android-build/WorkOrder.apk
```

Или из каталога `cpp/`:

```bash
cmake --preset android-arm64
cmake --build ../build/cpp-android-arm64 --target WorkOrder_make_apk
```

## Структура Android-пакета

```
cpp/android/
  AndroidManifest.xml    # com.workorder, portrait, storage permissions
  res/drawable/icon.png
```

QML (desktop + mobile + Common) и шрифты упаковываются в **qrc** на всех платформах.

## Отладка

```bash
adb logcat | rg -i 'WorkOrder|Qt|qml|FATAL|com.workorder'
```

Package C++ APK: **`com.workorder`**. Python APK (pysidedeploy): `com.workorder.workorder`.

Если приложение сразу закрывается — проверьте logcat на `Failed to load QML` (частая причина: неверный URL для `qrc:`).

Данные приложения: `QStandardPaths::AppDataLocation/data/`.

## Desktop vs Android

| | Desktop kit | Android kit |
|---|-------------|-------------|
| UI | desktop / mobile (`Type`) | только mobile |
| QML | `qrc:/resources/qml/...` | `qrc:/resources/qml/...` |
| Запуск | `run-desktop`, `run-mobile` | APK / Qt Creator Run |
