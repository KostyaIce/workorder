#ifndef WORKORDER_UTILS_APP_PATHS_H
#define WORKORDER_UTILS_APP_PATHS_H

#include <QString>

namespace workorder
{

class AppPaths
{
public:
    static QString projectRoot();
    static QString storageDir();
    static QString dataDir();
    static QString logDir();
    static QString dbDir();
    static QString configDir();
    // Alias for dataDir() kept for older call sites.
    static QString projectDataDir();
    static bool isAndroidRuntime();
    static void createPaths();
};

} // namespace workorder

#endif // WORKORDER_UTILS_APP_PATHS_H
