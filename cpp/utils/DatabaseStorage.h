#ifndef WORKORDER_UTILS_DB_STORAGE_H
#define WORKORDER_UTILS_DB_STORAGE_H

#include "Types.h"

#include <QPair>
#include <QString>

namespace workorder
{

class DatabaseStorage
{
public:
    static QString projectDataDir();
    static QString defaultClientsDbPath();
    static QString objectDbPath(const QString &clientName, const QString &clientId);
    static QString defaultSettingsPath();
    static QString defaultReportsDir();
    static QString resolveDbPath(const QString &filePath, const QString &defaultPath);

    static QPair<QString, int> createWorksDatabase(const QString &clientName, const QString &clientId);
    static bool addWorkEntry(const QString &clientName, const QString &clientId, const StringMap &data);
    static StringMapList loadWorks(const QString &clientName, const QString &clientId);
    static bool delWorkEntry(const QString &clientName, const QString &clientId, const StringMap &data);
    static bool updateWorkEntry(const QString &clientName, const QString &clientId, const StringMap &data);

    static StringMap loadAppSettings(const QString &filePath = QString());
    static QString saveAppSettings(const StringMap &settings, const QString &filePath = QString());
};

} // namespace workorder

#endif // WORKORDER_UTILS_DB_STORAGE_H
