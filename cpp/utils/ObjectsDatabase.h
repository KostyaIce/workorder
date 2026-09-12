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
    // Releases the cached connection, required before the client database file is renamed.
    static void closeDatabase(const QString &clientName, const QString &clientId);
    static bool addObjectEntry(const QString &clientName, const QString &clientId,
                               const QString &name, const QString &address = QString());
    static StringMapList loadObjects(const QString &clientName, const QString &clientId);
    static bool delObjectEntry(const QString &clientName, const QString &clientId, const StringMap &data);
    static bool updateObjectName(const QString &clientName, const QString &clientId, const StringMap &data);
    static bool updateObjectLastOrderAt(const QString &clientName, const QString &clientId, const QString &objectId);
    // Insert objects from source db file that are missing in target (by id).
    static int mergeFromDatabase(const QString &sourceDbPath,
                                 const QString &clientName,
                                 const QString &clientId);
};

} // namespace workorder

#endif // WORKORDER_UTILS_OBJECTS_DB_H
