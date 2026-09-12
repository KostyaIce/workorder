#ifndef WORKORDER_UTILS_EXPENSES_DATABASE_H
#define WORKORDER_UTILS_EXPENSES_DATABASE_H

#include "Types.h"

#include <QList>
#include <QString>
#include <QStringList>

namespace workorder
{

class ExpensesDatabase
{
public:
    static void createExpensesTable(const QString &clientName, const QString &clientId);
    static void closeDatabase(const QString &clientName, const QString &clientId);
    static StringMap addExpense(const QString &clientName, const QString &clientId,
                                const StringMap &data);
    static bool updateExpense(const QString &clientName, const QString &clientId,
                              const StringMap &data);
    static bool deleteExpense(const QString &clientName, const QString &clientId,
                              const QString &expenseId);
    static StringMapList loadExpensesByStartOrder(const QString &clientName,
                                                  const QString &clientId,
                                                  const QString &objectId,
                                                  qint64 startOrderAt);
    static StringMapList getResultExpenses(const QString &clientName,
                                           const QString &clientId,
                                           const QStringList &objectIds,
                                           const QList<qint64> &ordersAt);
    static StringMapList getOrderTotals(const QString &clientName,
                                        const QString &clientId,
                                        const QString &objectId);
    static int mergeFromDatabase(const QString &sourceDbPath,
                                 const QString &clientName,
                                 const QString &clientId);
};

} // namespace workorder

#endif // WORKORDER_UTILS_EXPENSES_DATABASE_H
