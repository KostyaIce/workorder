# Яндекс.Диск: OAuth (desktop + mobile идентификаторы)

Единые константы: `cpp/backend/YandexDiskConfig.h` и CMake cache в `cpp/CMakeLists.txt`.

| Параметр | Значение по умолчанию | Где менять |
|----------|----------------------|------------|
| OAuth Client ID | `d3e1a705454a448b841e617117fec451` | `-DWORKORDER_YANDEX_OAUTH_CLIENT_ID=...` или `YandexDiskConfig.h` |
| Android application id | `com.workorder` | `cpp/android/AndroidManifest.xml`, `-DWORKORDER_MOBILE_APPLICATION_ID=...` |
| iOS Bundle ID | `com.workorder` | `-DWORKORDER_IOS_BUNDLE_ID=...` |
| Redirect scheme | `workorder` | `-DWORKORDER_OAUTH_CALLBACK_SCHEME=...` |
| Mobile redirect URI | `workorder://oauth-callback` | scheme + host в коде |
| Login SDK iOS scheme | `yx` + Client ID | `cpp/ios/Info.plist.in` (генерируется CMake) |
| Desktop redirect | `http://127.0.0.1:53683/callback` | порт в `YandexDiskConfig::desktopOAuthPort` |

Право на Диск: **`cloud_api:disk.app_folder`**.

## Регистрация на [oauth.yandex.ru](https://oauth.yandex.ru)

### Платформы iOS и Android

1. **iOS**
   - Bundle ID: `com.workorder` (или ваш `-DWORKORDER_IOS_BUNDLE_ID`).
   - В кабинете Яндекса App ID имеет вид **`{TeamID}.com.workorder`** (Team ID из Apple Developer → Membership).
   - URL scheme для Login SDK: **`yxd3e1a705454a448b841e617117fec451`** (после смены Client ID пересоберите iOS — CMake подставит `yx` + id в `Info.plist`).

2. **Android**
   - Имя пакета: **`com.workorder`** (как в `AndroidManifest.xml`).
   - Отпечаток **SHA-256** release-ключа (как для Google Play / подписи APK).

3. **Redirect URI (мобильный браузер / PKCE, как в Skedula)**
   - Добавьте в раздел **«Веб-сервисы»**: **`workorder://oauth-callback`**

### Desktop (macOS / Windows / Linux)

- Redirect URI: **`http://127.0.0.1:53683/callback`**

## Файлы проекта

| Платформа | Файл |
|-----------|------|
| iOS URL schemes | `cpp/ios/Info.plist.in` → `build/.../ios_package/Info.plist` |
| iOS CMake | `cmake/CppIos.cmake` |
| Android deep link | `cpp/android/AndroidManifest.xml` (intent-filter `workorder` / `oauth-callback`) |

На iOS/Android вход через Login SDK и обработка redirect в C++ пока **не подключены** (как в planer — следующий шаг). Сейчас зафиксированы идентификаторы, чтобы заранее создать приложение в Яндексе.

## После смены Client ID

Отключите Диск в настройках и войдите снова. Обновите iOS scheme `yx...`, redirect URI и платформы в oauth.yandex.ru.
