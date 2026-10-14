#ifndef WORKORDER_UTILS_DATABASE_CLOUD_JSON_H
#define WORKORDER_UTILS_DATABASE_CLOUD_JSON_H

#include <QString>

namespace workorder
{

// Cloud Yandex.Disk stores JSON payloads in *.db files; local app keeps SQLite.
class DatabaseCloudJson
{
public:
    static int mergeClientsFromJsonFile(const QString &jsonPath, const QString &dbPath = QString());
    static bool exportClientsToJsonFile(const QString &dbPath, const QString &jsonPath);

    static int mergeServicesFromJsonFile(const QString &jsonPath);
    static bool exportServicesToJsonFile(const QString &jsonPath);

    static int mergeClientDbFromJsonFile(const QString &jsonPath,
                                         const QString &clientName,
                                         const QString &clientId);
    static bool exportClientDbToJsonFile(const QString &clientName,
                                         const QString &clientId,
                                         const QString &jsonPath);
};

} // namespace workorder

#endif // WORKORDER_UTILS_DATABASE_CLOUD_JSON_H
