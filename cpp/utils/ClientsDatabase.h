#ifndef WORKORDER_UTILS_CLIENTS_DB_H
#define WORKORDER_UTILS_CLIENTS_DB_H

#include "Types.h"

#include <QString>

namespace workorder
{

class ClientsDatabase
{
public:
    static void createClientTable(const QString &dbPath = QString());
    static bool addClientEntry(const StringMap &data, const QString &dbPath = QString());
    static bool updateClientEntry(const StringMap &data, const QString &dbPath = QString());
    static StringMapList loadClients(const QString &dbPath = QString());
    static bool delClientEntry(const StringMap &data, const QString &dbPath = QString());
    // Insert rows from source that are missing in target (by primary key id).
    static int mergeFromDatabase(const QString &sourceDbPath, const QString &targetDbPath = QString());

private:
    static QString resolveDbPath(const QString &dbPath);
};

} // namespace workorder

#endif // WORKORDER_UTILS_CLIENTS_DB_H
