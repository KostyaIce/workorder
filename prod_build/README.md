# Сборка WorkOrder: краткая инструкция

Все команды выполняются **из корня `workorder`**.

Мобильные сборки всегда используют **mobile-интерфейс**: оба iOS-скрипта
передают CMake `-DType=mobile`, Android C++ собирается с тем же параметром.
Это относится и к тестовым, и к production-сборкам;
дополнительный аргумент `mobile` при запуске не нужен.

## iOS

Нужны macOS, Xcode, Qt 6.8.3 для iOS и macOS (по умолчанию `~/Qt/6.8.3`).
Оба режима собираются для **iPhone** (`TARGETED_DEVICE_FAMILY=1`), без нативной
поддержки iPad. Иконка `AppIcon` компилируется Xcode из `cpp/ios/Assets.xcassets`.
Apple может разрешать запуск iPhone-приложения на iPad в режиме совместимости;
настройка iPhone-only не запрещает такой запуск.
Версия берётся из `version.mk`: `1.0.27` → версия приложения `1.0.27`,
номер сборки iOS (`CFBundleVersion`) `1000027`.
Формула: `major × 1000000 + minor × 1000 + patch`.

### Для тестов на iPhone

```bash
bash prod_build/build_ios.sh development
# Другая команда разработчика:
TEAM_ID=XXXXXXXXXX bash prod_build/build_ios.sh development
# Distribution-подпись для зарегистрированных устройств:
bash prod_build/build_ios.sh ad-hoc
```

По умолчанию тестовая команда — `74FAM6RATH`. Нужны аккаунт в Xcode и
зарегистрированное устройство. Результаты:
`build/ios-local/WorkOrder-development.ipa` или `WorkOrder-ad-hoc.ipa`.
Установка: Xcode → Window → Devices and Simulators → Installed Apps → `+`.

### Для App Store / TestFlight

Подготовьте соседний каталог `../workorder-signing/ios/`:

- `distribution.p12` — сертификат с приватным ключом; импортируйте в Keychain;
- `WorkOrder_AppStore.mobileprovision` — App Store-профиль для `com.workorder`.

```bash
# Проверить инструменты и подпись, установить профиль для Xcode:
bash prod_build/build_ios_app_store.sh --check
# Собрать архив и подписанную IPA:
bash prod_build/build_ios_app_store.sh
# Пример другого расположения файлов:
SIGNING_DIR=/absolute/path/workorder-signing bash prod_build/build_ios_app_store.sh
```

Результат: `build/ios-app-store/WorkOrder.ipa`. Загрузите через Transporter.
После обработки сборка доступна в TestFlight; выпуск в App Store оформляется
отдельно в App Store Connect. Эта IPA не предназначена для прямой установки.
Team ID и сертификат выбираются из профиля; при нескольких подходящих
сертификатах задайте `SIGN_IDENTITY=<SHA-1>`.

## Android

Нужны Qt Android arm64-v8a и host Qt, CMake, Ninja, JDK, Android SDK/NDK.
Собираются исключительно исходники `cpp/`, Python-прототип не используется.
Версия берётся из `version.mk`, аналогично iOS: `1.0.27` →
`versionName=1.0.27`, `versionCode=1000027`. Применяется к debug и release APK.

```bash
# Debug APK для тестов:
export ANDROID_NDK_ROOT="$HOME/Library/Android/sdk/ndk/<версия-для-вашего-Qt>"
bash prod_build/build_android_apk.sh debug
# Production APK:
export ANDROID_BUILD_TOOLS_VERSION=35.0.0 # установленная версия SDK Build Tools
bash prod_build/build_android_apk.sh release
# Другой каталог ключей:
SIGNING_DIR=/absolute/path/workorder-signing bash prod_build/build_android_apk.sh release
```

Production-ключи: `../workorder-signing/key.properties` и `workorder-key.jks`.
Пример `key.properties` (замените значения в угловых скобках):

```properties
storeFile=workorder-key.jks
storePassword=<пароль хранилища>
keyAlias=workorder
keyPassword=<пароль ключа>
```

`storeFile` задаётся относительно каталога подписи или абсолютным путём.
Используйте обычные строки `key=value`, без Java-properties escape-последовательностей.
Release APK выравнивается через `zipalign`, подписывается `apksigner`, подпись проверяется.
Результат: `build/android-cpp-debug/WorkOrder-debug.apk` или
`build/android-cpp-release/WorkOrder-release.apk`.

```bash
adb install -r /path/to/WorkOrder.apk
```

## Desktop

```bash
# macOS: нативная Qt/C++ сборка
cmake -S cpp -B build/macos-cpp -DCMAKE_PREFIX_PATH="$HOME/Qt/6.8.3/macos" -DCMAKE_BUILD_TYPE=Release -DType=desktop
cmake --build build/macos-cpp --parallel
```

```powershell
# Windows: приложение и установщик
powershell -ExecutionPolicy Bypass -File .\prod_build\windows\build.ps1
powershell -ExecutionPolicy Bypass -File .\prod_build\windows\pack.ps1
```

Windows-результаты: `prod_build/windows/`.
Старые `prod_build/android/` (PySide/buildozer) и `prod_build/mac/` (PyInstaller)
относятся к Python-прототипу и не используются для нативной сборки.
Подробности: [docs/prod-build.md](../docs/prod-build.md).
