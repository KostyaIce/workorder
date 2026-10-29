# Production build (portable)

Как в dapchainvpn-client: отдельно **build** и **pack**, артефакты по ОС.

```
prod_build/
├── build.sh / pack.sh     # общие entry (bash)
├── validate.sh
├── targets/               # windows.sh, osx.sh
├── packaging/             # windows.sh, osx.sh
├── windows/               # PowerShell build/pack + артефакты
└── mac/                   # bash build/pack + PyInstaller + артефакты
```

## Мобильные сборки и production-подпись

Команды запускаются из корня проекта. iOS требует macOS, Xcode, CocoaPods и Qt iOS;
Android — Qt Android, host Qt, CMake/Ninja, JDK и Android SDK/NDK.
Обе мобильные платформы собираются из `cpp/` с `-DType=mobile`.
iOS-скрипты автоматически выполняют `pod install` для нативного YandexLoginSDK
и собирают `WorkOrder.xcworkspace`.

```bash
# iOS: тесты на зарегистрированном iPhone (automatic signing)
bash prod_build/build_ios.sh development
bash prod_build/build_ios.sh ad-hoc
# iOS: App Store / TestFlight (manual distribution signing)
bash prod_build/build_ios_app_store.sh --check
bash prod_build/build_ios_app_store.sh
# Android: debug / production APK
export ANDROID_NDK_ROOT=/absolute/path/to/android-ndk
export ANDROID_BUILD_TOOLS_VERSION=35.0.0
bash prod_build/build_android_apk.sh debug
bash prod_build/build_android_apk.sh release
```

Тестовые IPA: `build/ios-local/WorkOrder-development.ipa` или
`WorkOrder-ad-hoc.ipa`. Distribution IPA: `build/ios-app-store/WorkOrder.ipa`.
App Store IPA загружается через Transporter; для прямой установки нужен тестовый режим.
Android release создаётся через Qt/CMake и подписывается `apksigner` с production-ключом.
Результат: `build/android-cpp-release/WorkOrder-release.apk`.

Файлы подписи располагаются **вне репозитория**, рядом с проектом:

```text
Project/
  workorder/
  workorder-signing/
    key.properties
    workorder-key.jks
    ios/
      distribution.p12
      WorkOrder_AppStore.mobileprovision
```

`key.properties` — строки `key=value` (без Java-properties escape-последовательностей):

```properties
storeFile=workorder-key.jks
storePassword=<пароль хранилища>
keyAlias=workorder
keyPassword=<пароль ключа>
```

`storeFile` может быть абсолютным или относительным к каталогу подписи.
Как создать ключ и снять SHA-256: [android-signing-key.md](android-signing-key.md).
Переопределение общего каталога: `SIGNING_DIR=/absolute/path`.
Для iOS доступны `IOS_CERT_DIR`, `IOS_PROFILE`, `SIGN_IDENTITY` (SHA-1).
Импортируйте `distribution.p12` с приватным ключом в Keychain вручную.
Скрипт проверяет срок, тип и bundle ID профиля, выбирает установленный сертификат
из профиля и берёт production Team ID из него. Если сертификатов несколько,
укажите `SIGN_IDENTITY`. `--check` также устанавливает профиль для Xcode.
По умолчанию bundle ID — `com.workorder`; можно задать `BUNDLE_ID`.
Тестовая команда по умолчанию — `74FAM6RATH`, переопределяется через `TEAM_ID`.

## Windows (C++ desktop)

```powershell
powershell -ExecutionPolicy Bypass -File .\prod_build\windows\build.ps1
powershell -ExecutionPolicy Bypass -File .\prod_build\windows\pack.ps1
```

Или одной цепочкой после `build`:

```powershell
.\prod_build\windows\build.ps1 -BuildType release
.\prod_build\windows\pack.ps1
```

Результат в `prod_build/windows/`:

| Путь | Кто создаёт |
|------|-------------|
| `build/` | cmake/ninja |
| `dist/WorkOrder.exe` | build |
| `WorkOrder/` | pack (windeployqt, portable) |
| `WorkOrder-desktop-<ver>-setup.exe` | pack (NSIS installer) |

Нужен [NSIS](https://nsis.sourceforge.io/Download) (`makensis`). Установка: `winget install NSIS.NSIS`.

Опционально zip: `.\prod_build\windows\pack.ps1 -AlsoZip`.

На другом ПК: запустить `WorkOrder-desktop-*-setup.exe` (или скопировать папку `WorkOrder/`).

## macOS (Python / PyInstaller)

Этот раздел относится только к старому Python-прототипу. Для актуального
Qt/C++ приложения используйте нативные команды из [prod_build/README.md](../prod_build/README.md).

```bash
./prod_build/mac/build.sh desktop
./prod_build/mac/pack.sh
```

Или через общие скрипты:

```bash
./prod_build/build.sh --target osx release
./prod_build/pack.sh --target osx release
```

Результат в `prod_build/mac/`:

| Путь | Кто создаёт |
|------|-------------|
| `dist/WorkOrder.app` | build |
| `WorkOrder.app` | pack |
| `WorkOrder-<type>-<ver>.dmg` | pack |

## Иконка Windows

`resources/icons/appIcons/icon_win32.ico` (из `icon_linux.png`):

```powershell
python prod_build\generate_win_icon.py
```
