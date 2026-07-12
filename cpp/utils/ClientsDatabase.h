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
    static StringMapList loadClients(const QString &dbPath = QString());
    static bool delClientEntry(const StringMap &data, const QString &dbPath = QString());

private:
    static QString resolveDbPath(const QString &dbPath);
};

} // namespace workorder

#endif // WORKORDER_UTILS_CLIENTS_DB_H
