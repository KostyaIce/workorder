#ifndef WORKORDER_UTILS_WORKS_DB_H
#define WORKORDER_UTILS_WORKS_DB_H

#include "Types.h"

#include <QSqlQuery>
#include <QString>

namespace workorder
{

class WorksDatabase
{
public:
    static void createWorksTable(const QString &clientName, const QString &clientId);
    static StringMap addWork(const QString &clientName, const QString &clientId, const StringMap &data);
    static StringMapList loadWorks(const QString &clientName, const QString &clientId);
    static StringMapList loadWorksByObject(const QString &clientName, const QString &clientId, const QString &objectId);
    static StringMapList loadWorksByStartOrder(const QString &clientName, const QString &clientId,
                                               const QString &objectId, qint64 startOrderAt);
    static StringMapList loadWorksBySelectAt(const QString &clientName, const QString &clientId,
                                             const QString &objectId, qint64 startOrderAt);
    static QStringList loadSubobjectNames(const QString &clientName, const QString &clientId, const QString &objectId);
    static bool deleteWork(const QString &clientName, const QString &clientId, const QString &workId);
    static bool updateWork(const QString &clientName, const QString &clientId, const StringMap &data);
    static StringMapList getOrders(const QString &clientName, const QString &clientId, const QString &objectId);
    static StringMapList getResultWorks(const QString &clientName, const QString &clientId,
                                        const QStringList &objectIds, const QList<qint64> &ordersAt);
    // Insert works from source db file that are missing in target (by id).
    static int mergeFromDatabase(const QString &sourceDbPath,
                                 const QString &clientName,
                                 const QString &clientId);

private:
    static StringMap rowToWork(const QSqlQuery &query);
    static StringMap rowToResult(const QSqlQuery &query);
    static double parseQuantity(const QVariant &value);
    static int parsePercentSum(const QVariant &value);
};

} // namespace workorder

#endif // WORKORDER_UTILS_WORKS_DB_H
