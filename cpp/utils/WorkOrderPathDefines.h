#ifndef WORKORDER_UTILS_PATH_DEFINES_H
#define WORKORDER_UTILS_PATH_DEFINES_H

#include <QString>

namespace workorder
{

// Per-OS application storage layout (sandbox), similar to cellframe-wallet WalletStorage.
// Root is always a writable user/app sandbox (never /opt).
//
//   {STORAGE}/
//     data/
//       log/
//       db/
//       config/
//
// Override root via WORKORDER_DATA_DIR (points to STORAGE).
struct WorkOrderPathDefines
{
    static QString storagePath();
    static QString dataPath();
    static QString logPath();
    static QString dbPath();
    static QString configPath();
    // Default folder for reports when the user did not pick a path (Documents).
    static QString reportsPath();
    static QString configFilePath();

    static void createPaths();
};

} // namespace workorder

#endif // WORKORDER_UTILS_PATH_DEFINES_H
