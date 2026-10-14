#ifndef WORKORDER_BACKEND_YANDEX_DISK_CONFIG_H
#define WORKORDER_BACKEND_YANDEX_DISK_CONFIG_H

// OAuth app settings (Yandex OAuth console). Override at build time:
// -DWORKORDER_YANDEX_OAUTH_CLIENT_ID=your_client_id
#ifndef WORKORDER_YANDEX_OAUTH_CLIENT_ID
#define WORKORDER_YANDEX_OAUTH_CLIENT_ID "d3e1a705454a448b841e617117fec451"
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
