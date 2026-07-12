#ifndef WORKORDER_UTILS_OBJECTS_DB_H
#define WORKORDER_UTILS_OBJECTS_DB_H

#include "Types.h"

#include <QString>

namespace workorder
{

class ObjectsDatabase
{
public:
    static void createObjectDatabase(const QString &clientName, const QString &clientId);
    static bool addObjectEntry(const QString &clientName, const QString &clientId,
                               const QString &name, const QString &address = QString());
    static StringMapList loadObjects(const QString &clientName, const QString &clientId);
    static bool delObjectEntry(const QString &clientName, const QString &clientId, const StringMap &data);
    static bool updateObjectName(const QString &clientName, const QString &clientId, const StringMap &data);
    static bool updateObjectLastOrderAt(const QString &clientName, const QString &clientId, const QString &objectId);
};

} // namespace workorder

#endif // WORKORDER_UTILS_OBJECTS_DB_H
