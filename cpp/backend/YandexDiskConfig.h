#ifndef WORKORDER_BACKEND_YANDEX_DISK_CONFIG_H
#define WORKORDER_BACKEND_YANDEX_DISK_CONFIG_H

// Client id is defined in cpp/CMakeLists.txt and passed as a compile definition.
#ifndef WORKORDER_YANDEX_OAUTH_CLIENT_ID
#error WORKORDER_YANDEX_OAUTH_CLIENT_ID must be set from cpp/CMakeLists.txt
#endif

// Must match Android package / iOS bundle id (see cmake/CppIos.cmake, cpp/android/AndroidManifest.xml).
#ifndef WORKORDER_MOBILE_APPLICATION_ID
#define WORKORDER_MOBILE_APPLICATION_ID "com.workorder"
#endif

#ifndef WORKORDER_OAUTH_CALLBACK_SCHEME
#define WORKORDER_OAUTH_CALLBACK_SCHEME "workorder"
#endif

namespace workorder
{

struct YandexDiskConfig
{
    static constexpr const char *oauthClientId = WORKORDER_YANDEX_OAUTH_CLIENT_ID;
    static constexpr const char *oauthScopes = "cloud_api:disk.app_folder";
    static constexpr const char *oauthAuthorizeUrl = "https://oauth.yandex.ru/authorize";
    static constexpr const char *oauthTokenUrl = "https://oauth.yandex.ru/token";
    static constexpr int desktopOAuthPort = 53683;

    // Mobile OAuth redirect (browser / Login SDK fallback), same pattern as Skedula planer.
    static constexpr const char *mobileApplicationId = WORKORDER_MOBILE_APPLICATION_ID;
    static constexpr const char *mobileOAuthCallbackScheme = WORKORDER_OAUTH_CALLBACK_SCHEME;
    static constexpr const char *mobileOAuthCallbackHost = "oauth-callback";
    // Yandex Login SDK iOS URL scheme: "yx" + oauthClientId (no separators).
};

} // namespace workorder

#endif // WORKORDER_BACKEND_YANDEX_DISK_CONFIG_H
