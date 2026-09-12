#include "ExpensesDatabase.h"

#include "DatabaseStorage.h"

#include <QDateTime>
#include <QDir>
#include <QFileInfo>
#include <QSqlDatabase>
#include <QSqlError>
#include <QSqlQuery>
#include <QUuid>

namespace workorder
{

namespace
{

const char *kExpenseColumns =
    "id, object_id, start_order_at, description, amount, created_at, updated_at";

QString connectionName(const QString &clientName, const QString &clientId)
{
    return QStringLiteral("expenses_%1_%2").arg(clientName, clientId);
}

QSqlDatabase openDatabase(const QString &clientName, const QString &clientId)
{
    const QString dbPath = DatabaseStorage::objectDbPath(clientName, clientId);
    const QString name = connectionName(clientName, clientId);
    if(QSqlDatabase::contains(name))
        return QSqlDatabase::database(name);

    QDir().mkpath(QFileInfo(dbPath).absolutePath());

    QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), name);
    db.setDatabaseName(dbPath);
    if(!db.open())
        qWarning("Failed to open expenses database: %s", qPrintable(db.lastError().text()));
    return db;
}

StringMap rowToExpense(const QSqlQuery &query)
{
    StringMap expense;
    expense.insert("id", query.value(0));
    expense.insert("object_id", query.value(1));
    expense.insert("start_order_at", query.value(2));
    expense.insert("description", query.value(3));
    expense.insert("amount", query.value(4));
    expense.insert("created_at", query.value(5));
    expense.insert("updated_at", query.value(6));
    return expense;
}

} // namespace

void ExpensesDatabase::createExpensesTable(const QString &clientName, const QString &clientId)
{
    QSqlDatabase db = openDatabase(clientName, clientId);
    QSqlQuery query(db);
    query.exec(QStringLiteral(
        "CREATE TABLE IF NOT EXISTS expenses ("
        "id TEXT PRIMARY KEY,"
        "object_id TEXT NOT NULL,"
        "start_order_at INTEGER NOT NULL,"
        "description TEXT NOT NULL,"
        "amount INTEGER NOT NULL,"
        "created_at INTEGER NOT NULL,"
        "updated_at INTEGER NOT NULL"
        ")"));
    query.exec(QStringLiteral(
        "CREATE INDEX IF NOT EXISTS idx_expenses_order"
        " ON expenses(object_id, start_order_at)"));
}

void ExpensesDatabase::closeDatabase(const QString &clientName, const QString &clientId)
{
    const QString name = connectionName(clientName, clientId);
    if(!QSqlDatabase::contains(name))
        return;

    {
        QSqlDatabase db = QSqlDatabase::database(name, false);
        if(db.isOpen())
            db.close();
    }
    QSqlDatabase::removeDatabase(name);
}

StringMap ExpensesDatabase::addExpense(const QString &clientName, const QString &clientId,
                                       const StringMap &data)
{
    const QString description = data.value("description").toString().trimmed();
    const int amount = data.value("amount").toInt();
    const QString objectId = data.value("object_id").toString();
    const qint64 startOrderAt = data.value("start_order_at").toLongLong();
    if(description.isEmpty() || amount <= 0 || objectId.isEmpty() || startOrderAt <= 0)
        return {};

    createExpensesTable(clientName, clientId);
    const QString expenseId = QUuid::createUuid().toString(QUuid::WithoutBraces);
    const qint64 now = QDateTime::currentSecsSinceEpoch();
    QSqlDatabase db = openDatabase(clientName, clientId);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "INSERT INTO expenses(%1) VALUES (?, ?, ?, ?, ?, ?, ?)")
                      .arg(QLatin1String(kExpenseColumns)));
    query.addBindValue(expenseId);
    query.addBindValue(objectId);
    query.addBindValue(startOrderAt);
    query.addBindValue(description);
    query.addBindValue(amount);
    query.addBindValue(now);
    query.addBindValue(now);
    if(!query.exec())
    {
        qWarning("Failed to add expense: %s", qPrintable(query.lastError().text()));
        return {};
    }

    StringMap result = data;
    result.insert("id", expenseId);
    result.insert("description", description);
    result.insert("amount", amount);
    result.insert("created_at", now);
    result.insert("updated_at", now);
    return result;
}

bool ExpensesDatabase::updateExpense(const QString &clientName, const QString &clientId,
                                     const StringMap &data)
{
    const QString expenseId = data.value("id").toString();
    const QString description = data.value("description").toString().trimmed();
    const int amount = data.value("amount").toInt();
    if(expenseId.isEmpty() || description.isEmpty() || amount <= 0)
        return false;

    QSqlDatabase db = openDatabase(clientName, clientId);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "UPDATE expenses SET description = ?, amount = ?, updated_at = ? WHERE id = ?"));
    query.addBindValue(description);
    query.addBindValue(amount);
    query.addBindValue(QDateTime::currentSecsSinceEpoch());
    query.addBindValue(expenseId);
    if(!query.exec())
    {
        qWarning("Failed to update expense: %s", qPrintable(query.lastError().text()));
        return false;
    }
    return query.numRowsAffected() > 0;
}

bool ExpensesDatabase::deleteExpense(const QString &clientName, const QString &clientId,
                                     const QString &expenseId)
{
    if(expenseId.isEmpty())
        return false;

    QSqlDatabase db = openDatabase(clientName, clientId);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("DELETE FROM expenses WHERE id = ?"));
    query.addBindValue(expenseId);
    return query.exec() && query.numRowsAffected() > 0;
}

StringMapList ExpensesDatabase::loadExpensesByStartOrder(const QString &clientName,
                                                         const QString &clientId,
                                                         const QString &objectId,
                                                         qint64 startOrderAt)
{
    createExpensesTable(clientName, clientId);
    QSqlDatabase db = openDatabase(clientName, clientId);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "SELECT %1 FROM expenses WHERE object_id = ? AND start_order_at = ?"
        " ORDER BY created_at DESC").arg(QLatin1String(kExpenseColumns)));
    query.addBindValue(objectId);
    query.addBindValue(startOrderAt);
    if(!query.exec())
        return {};

    StringMapList result;
    while(query.next())
        result.append(rowToExpense(query));
    return result;
}

StringMapList ExpensesDatabase::getResultExpenses(const QString &clientName,
                                                  const QString &clientId,
                                                  const QStringList &objectIds,
                                                  const QList<qint64> &ordersAt)
{
    if(objectIds.isEmpty() || ordersAt.isEmpty())
        return {};

    createExpensesTable(clientName, clientId);
    QSqlDatabase db = openDatabase(clientName, clientId);
    StringMapList result;
    for(const QString &objectId : objectIds)
    {
        for(qint64 orderAt : ordersAt)
        {
            QSqlQuery query(db);
            query.prepare(QStringLiteral(
                "SELECT %1 FROM expenses WHERE object_id = ? AND start_order_at = ?"
                " ORDER BY created_at").arg(QLatin1String(kExpenseColumns)));
            query.addBindValue(objectId);
            query.addBindValue(orderAt);
            if(!query.exec())
                continue;
            while(query.next())
                result.append(rowToExpense(query));
        }
    }
    return result;
}

StringMapList ExpensesDatabase::getOrderTotals(const QString &clientName,
                                               const QString &clientId,
                                               const QString &objectId)
{
    createExpensesTable(clientName, clientId);
    QSqlDatabase db = openDatabase(clientName, clientId);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "SELECT start_order_at, SUM(amount) FROM expenses"
        " WHERE object_id = ? GROUP BY start_order_at"));
    query.addBindValue(objectId);
    if(!query.exec())
        return {};

    StringMapList result;
    while(query.next())
    {
        StringMap row;
        row.insert("start_order_at", query.value(0));
        row.insert("total_price", query.value(1));
        result.append(row);
    }
    return result;
}

int ExpensesDatabase::mergeFromDatabase(const QString &sourceDbPath,
                                        const QString &clientName,
                                        const QString &clientId)
{
    if(sourceDbPath.isEmpty() || !QFileInfo::exists(sourceDbPath)
        || clientName.isEmpty() || clientId.isEmpty())
        return 0;

    createExpensesTable(clientName, clientId);
    const QString srcConn = QStringLiteral("expenses_merge_src_%1").arg(sourceDbPath);
    int inserted = 0;
    {
        QSqlDatabase src = QSqlDatabase::contains(srcConn)
            ? QSqlDatabase::database(srcConn)
            : QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), srcConn);
        src.setDatabaseName(sourceDbPath);
        if(src.isOpen() || src.open())
        {
            const QStringList tables = src.tables();
            if(tables.contains(QStringLiteral("expenses")))
            {
                QSqlDatabase dst = openDatabase(clientName, clientId);
                QSqlQuery select(src);
                if(select.exec(QStringLiteral("SELECT %1 FROM expenses")
                                   .arg(QLatin1String(kExpenseColumns))))
                {
                    while(select.next())
                    {
                        QSqlQuery insert(dst);
                        insert.prepare(QStringLiteral(
                            "INSERT OR IGNORE INTO expenses(%1) VALUES (?, ?, ?, ?, ?, ?, ?)")
                                           .arg(QLatin1String(kExpenseColumns)));
                        for(int column = 0; column < 7; ++column)
                            insert.addBindValue(select.value(column));
                        if(insert.exec() && insert.numRowsAffected() > 0)
                            ++inserted;
                    }
                }
            }
        }
    }
    QSqlDatabase::removeDatabase(srcConn);
    qInfo("ExpensesDatabase::mergeFromDatabase inserted=%d from %s",
          inserted,
          qPrintable(sourceDbPath));
    return inserted;
}

} // namespace workorder
