#ifndef WORKORDER_UTILS_APP_PATHS_H
#define WORKORDER_UTILS_APP_PATHS_H

#include <QString>

namespace workorder
{

class AppPaths
{
public:
    static QString projectRoot();
    static QString dataDir();
    static QString projectDataDir();
    static bool isAndroidRuntime();

private:
    static QString resolveDataDir();
};

} // namespace workorder

#endif // WORKORDER_UTILS_APP_PATHS_H
