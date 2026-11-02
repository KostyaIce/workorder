# Сборка WorkOrder: краткая инструкция

Все команды выполняются **из корня `workorder`**.

Мобильные сборки всегда используют **mobile-интерфейс**: оба iOS-скрипта
передают CMake `-DType=mobile`, Android C++ собирается с тем же параметром.
Это относится и к тестовым, и к production-сборкам;
дополнительный аргумент `mobile` при запуске не нужен.

## iOS

Нужны macOS, Xcode, CocoaPods и Qt 6.8.3 для iOS и macOS
(по умолчанию `~/Qt/6.8.3`). Скрипты сами выполняют `pod install` и собирают
`WorkOrder.xcworkspace`: Яндекс.Диск на iOS подключается через нативный
**YandexLoginSDK** (`yx<Client ID>`), без desktop loopback-сервера.
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
- `WorkOrder_AppStore.mobileprovision` — App Store-профиль для `com.konstantin.workorder`.

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
bash prod_build/build_android_apk.sh debug
# Production APK (RuStore, direct install):
bash prod_build/build_android_apk.sh release
# Production AAB для Google Play:
bash prod_build/build_android_apk.sh aab
# Другой каталог ключей:
SIGNING_DIR=/absolute/path/workorder-signing bash prod_build/build_android_apk.sh release
```

SDK, NDK, build-tools и JDK 17/21 определяются автоматически из установленных.
При необходимости можно переопределить `ANDROID_SDK_ROOT`, `ANDROID_NDK_ROOT`,
`ANDROID_BUILD_TOOLS_VERSION`, `JAVA_HOME`, `QT_ROOT`, `QT_ANDROID_PATH`,
`QT_HOST_PATH`.

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
Результат: `build/android-cpp-debug/WorkOrder-debug.apk`,
`build/android-cpp-release/WorkOrder.apk` или
`build/android-cpp-release/WorkOrder.aab` для Google Play.

В конце сборки скрипт печатает время старта и завершения, длительность, размер APK,
имя пакета и готовые команды. Пример:

```text
============================================================
 СБОРКА ЗАВЕРШЕНА: 2026-11-01 15:12:40 MSK
 Старт: 2026-11-01 15:08:12 MSK
 Длительность: 268s
 APK: build/android-cpp-release/WorkOrder.apk (24M)
 Пакет: com.konstantin.workorder
...
```

Установка и запуск на подключённом устройстве:

```bash
# Проверить, что телефон виден
"$HOME/Library/Android/sdk/platform-tools/adb" devices

# Установить или обновить APK
"$HOME/Library/Android/sdk/platform-tools/adb" install -r build/android-cpp-debug/WorkOrder-debug.apk

# Запустить приложение
"$HOME/Library/Android/sdk/platform-tools/adb" shell monkey -p com.konstantin.workorder 1

# Логи приложения
bash prod_build/android/logcat_workorder.sh
```

Если `adb install` на Huawei/Honor падает с
`INSTALL_FAILED_ABORTED: User rejected permissions`:

- разблокируйте экран и подтвердите установку на самом устройстве;
- включите **Настройки → Система → Для разработчиков → Install via USB**
  (у некоторых прошивок пункт скрыт, пока не включена отладка по USB);
- отключите **Verify apps over USB**, если пункт есть;
- при повторной попытке на экране должно появиться подтверждение установки.

SDK, NDK, build-tools и JDK 17/21 определяются автоматически. Если установлена
preview-платформа (например `android-37.0`), скрипт собирает через временный SDK
только со стабильными платформами, чтобы Gradle не падал на `compileSdk`.

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
