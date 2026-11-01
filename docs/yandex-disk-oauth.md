# Яндекс.Диск: OAuth (desktop + mobile идентификаторы)

Клиентский идентификатор задаётся только в `cpp/CMakeLists.txt`. CMake передаёт его в C++ и подставляет в iOS `Info.plist`.

| Параметр | Значение по умолчанию | Где менять |
|----------|----------------------|------------|
| OAuth Client ID | `e015e5639e814d569f163477e7eb9415` | `cpp/CMakeLists.txt` |
| Android application id | `com.konstantin.workorder` | `cpp/android/AndroidManifest.xml` и Java-пакет `cpp/android/src/com/konstantin/workorder` |
| iOS Bundle ID | `com.konstantin.workorder` | `-DWORKORDER_IOS_BUNDLE_ID=...` |
| Android Auth SDK | `com.yandex.android:authsdk:3.1.3` | `cpp/android/build.gradle` |
| Android SDK scheme | `yx` + Client ID | генерируется SDK из `YANDEX_CLIENT_ID` |
| iOS Login SDK scheme | `yx` + Client ID | `cpp/ios/Info.plist.in` (генерируется CMake) |
| Desktop redirect | `http://127.0.0.1:53683/callback` | порт в `YandexDiskConfig::desktopOAuthPort` |

Право на Диск: **`cloud_api:disk.app_folder`**.

## Регистрация на [oauth.yandex.ru](https://oauth.yandex.ru)

### Платформы iOS и Android

1. **iOS**
   - Bundle ID: `com.konstantin.workorder` (или ваш `-DWORKORDER_IOS_BUNDLE_ID`).
   - В кабинете Яндекса App ID имеет вид **`{TeamID}.com.konstantin.workorder`** (Team ID из Apple Developer → Membership).
   - URL scheme для Login SDK: **`yxe015e5639e814d569f163477e7eb9415`** (после смены Client ID пересоберите iOS — CMake подставит `yx` + id в `Info.plist`).

2. **Android**
   - Имя пакета: **`com.konstantin.workorder`** (как в `AndroidManifest.xml`).
   - Отпечаток **SHA-256** release-ключа. Как создать ключ и снять отпечаток: [android-signing-key.md](android-signing-key.md).
   - Право на Диск: **`cloud_api:disk.app_folder`**.

   Android использует нативный **Yandex Auth SDK** (`com.yandex.android:authsdk:3.1.3`).
   SDK сам открывает Яндекс-приложение, Chrome Custom Tabs или WebView и
   возвращает токен через схему **`yx<Client ID>`**. Отдельный redirect URI
   для Android вручную регистрировать не нужно; главное — пакет, SHA-256 и
   Client ID должны совпадать с настройками приложения в oauth.yandex.ru.

   Для iOS также используется нативный Login SDK со схемой
   **`yx<Client ID>`** и `ASWebAuthenticationSession`.

### Desktop (macOS / Windows / Linux)

- Redirect URI: **`http://127.0.0.1:53683/callback`**

## Файлы проекта

| Платформа | Файл |
|-----------|------|
| iOS URL schemes | `cpp/ios/Info.plist.in` → `build/.../ios_package/Info.plist` |
| iOS CMake | `cmake/CppIos.cmake` |
| iOS Login SDK | `cpp/ios/YandexAuth.swift`, `cpp/ios/YandexAuth.mm`, `cpp/ios/YandexAuth.h` |
| iOS CocoaPods | `prod_build/ios_pods.sh` (YandexLoginSDK, `WorkOrder.xcworkspace`) |
| Android Gradle | `cpp/android/build.gradle` (`com.yandex.android:authsdk:3.1.3`) |
| Android Java bridge | `cpp/android/src/com/konstantin/workorder/YandexAuthHelper.java` |
| Android C++ bridge | `cpp/backend/YandexDiskOAuthFlow.cpp` |

На iOS вход идёт через **YandexLoginSDK** (`cpp/ios/YandexAuth.swift`), который
подключается CocoaPods в `prod_build/ios_pods.sh`. На Android используется
**Yandex Auth SDK** через `YandexAuthHelper.java` и JNI-мост в
`YandexDiskOAuthFlow.cpp`. Сборка iOS использует `WorkOrder.xcworkspace`.

## После смены Client ID

Отключите Диск в настройках и войдите снова. Обновите scheme `yx...` и
платформы iOS/Android (package + SHA-256) в oauth.yandex.ru.
