#ifndef WORKORDER_UTILS_SERVICES_DB_H
#define WORKORDER_UTILS_SERVICES_DB_H

#include "Types.h"

#include <QString>

namespace workorder
{

class ServicesDatabase
{
public:
    static QString defaultServicesDbPath();
    static void createServicesTable();
    static bool addService(const StringMap &data);
    static bool deleteService(const QString &serviceId);
    static bool updateService(const StringMap &data);
    static StringMapList loadServices();
    static StringMap getServiceById(const QString &serviceId);
    static StringMapList searchServices(const QString &query);
    // Insert rows from source that are missing locally (by primary key id).
    static int mergeFromDatabase(const QString &sourceDbPath);

private:
    static int parsePriceCents(const QVariant &value);
    static QString keywordsFromName(const QString &name);
};

} // namespace workorder

#endif // WORKORDER_UTILS_SERVICES_DB_H
