#include "WorksDatabase.h"

#include "DatabaseStorage.h"

#include <QDateTime>
#include <QDir>
#include <QFileInfo>
#include <QSet>
#include <QSqlDatabase>
#include <QSqlError>
#include <QSqlQuery>
#include <QUuid>

namespace workorder
{

namespace
{

const char *kWorksSelectColumns =
    "id, object_id, service_id, subobject_name, name, price, unit, quantity,"
    " created_at, updated_at, start_order_at, coefficients, percent_sum";

const QSet<QString> kWorksColumns = {
    "id", "object_id", "service_id", "subobject_name", "name", "price", "unit", "quantity",
    "created_at", "updated_at", "start_order_at", "coefficients", "percent_sum",
};

QString connectionName(const QString &clientName, const QString &clientId)
{
    return QStringLiteral("works_%1_%2").arg(clientName, clientId);
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
        qWarning("Failed to open works database: %s", qPrintable(db.lastError().text()));

    return db;
}

QSet<QString> tableColumns(QSqlDatabase &db)
{
    QSet<QString> columns;
    QSqlQuery query(db);
    query.exec(QStringLiteral("PRAGMA table_info(completed_works)"));
    while(query.next())
        columns.insert(query.value(1).toString());
    return columns;
}

QString notNullText(const QVariant &value)
{
    QString text = value.toString().trimmed();
    if(text.isNull())
        text = QStringLiteral("");
    return text;
}

} // namespace

double WorksDatabase::parseQuantity(const QVariant &value)
{
    double quantity = value.isValid() ? value.toDouble() : 1.0;
    if(quantity <= 0.0)
        quantity = 1.0;
    return qRound(quantity * 1000.0) / 1000.0;
}

int WorksDatabase::parsePercentSum(const QVariant &value)
{
    bool ok = false;
    int percentSum = value.toInt(&ok);
    if(!ok)
        percentSum = 100;
    return qMax(percentSum, 100);
}

StringMap WorksDatabase::rowToWork(const QSqlQuery &query)
{
    StringMap row;
    row.insert("id", query.value(0));
    row.insert("object_id", query.value(1));
    row.insert("service_id", query.value(2));
    row.insert("subobject_name", query.value(3));
    row.insert("name", query.value(4));
    row.insert("price", query.value(5));
    row.insert("unit", query.value(6));
    row.insert("quantity", query.value(7));
    row.insert("created_at", query.value(8));
    row.insert("updated_at", query.value(9));
    row.insert("start_order_at", query.value(10));
    row.insert("coefficients", query.value(11));
    row.insert("percent_sum", query.value(12));
    return row;
}

StringMap WorksDatabase::rowToResult(const QSqlQuery &query)
{
    StringMap row;
    row.insert("subobject_name", query.value(0));
    row.insert("name", query.value(1));
    row.insert("price", query.value(2));
    row.insert("unit", query.value(3));
    row.insert("quantity", query.value(4));
    row.insert("start_order_at", query.value(5));
    row.insert("coefficients", query.value(6));
    row.insert("percent_sum", query.value(7));
    return row;
}

void WorksDatabase::createWorksTable(const QString &clientName, const QString &clientId)
{
    QSqlDatabase db = openDatabase(clientName, clientId);
    const QSet<QString> columns = tableColumns(db);
    if(!columns.isEmpty() && columns != kWorksColumns)
    {
        qWarning("completed_works table schema mismatch, recreating table");
        QSqlQuery(db).exec(QStringLiteral("DROP TABLE completed_works"));
    }

    QSqlQuery query(db);
    query.exec(QStringLiteral(
        "CREATE TABLE IF NOT EXISTS completed_works ("
        "id TEXT PRIMARY KEY,"
        "object_id TEXT NOT NULL,"
        "service_id TEXT NOT NULL,"
        "subobject_name TEXT NOT NULL DEFAULT '',"
        "name TEXT NOT NULL,"
        "price INTEGER NOT NULL,"
        "unit TEXT,"
        "quantity NUMERIC(18, 3) NOT NULL DEFAULT 1,"
        "created_at INTEGER NOT NULL DEFAULT 0,"
        "updated_at INTEGER NOT NULL DEFAULT 0,"
        "start_order_at INTEGER NOT NULL DEFAULT 0,"
        "coefficients TEXT NOT NULL DEFAULT '',"
        "percent_sum INTEGER NOT NULL DEFAULT 100"
        ")"));
}

StringMap WorksDatabase::addWork(const QString &clientName, const QString &clientId, const StringMap &data)
{
    if(data.isEmpty())
        return {};

    const QString name = data.value("name").toString().trimmed();
    if(name.isEmpty())
        return {};

    const QString workId = QUuid::createUuid().toString(QUuid::WithoutBraces);
    const QString objectId = data.value("object_id").toString();
    const QString serviceId = data.value("service_id").toString();
    const QString subobjectName = notNullText(data.value("subobject_name"));
    const int price = data.value("price").toInt();
    const QString unit = data.value("unit").toString().trimmed();
    const double quantity = parseQuantity(data.value("quantity"));
    const QString coefficients = notNullText(data.value("coefficients"));
    const int percentSum = parsePercentSum(data.value("percent_sum"));
    const qint64 now = QDateTime::currentSecsSinceEpoch();
    const qint64 startOrderAt = data.contains("start_order_at")
        ? data.value("start_order_at").toLongLong()
        : now;

    createWorksTable(clientName, clientId);

    QSqlDatabase db = openDatabase(clientName, clientId);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "INSERT INTO completed_works ("
        "id, object_id, service_id, subobject_name, name, price, unit, quantity,"
        " created_at, updated_at, start_order_at, coefficients, percent_sum"
        ") VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"));
    query.addBindValue(workId);
    query.addBindValue(objectId);
    query.addBindValue(serviceId);
    query.addBindValue(subobjectName);
    query.addBindValue(name);
    query.addBindValue(price);
    query.addBindValue(unit);
    query.addBindValue(quantity);
    query.addBindValue(now);
    query.addBindValue(now);
    query.addBindValue(startOrderAt);
    query.addBindValue(coefficients);
    query.addBindValue(percentSum);

    if(!query.exec())
    {
        const QSqlError error = query.lastError();
        qWarning("WorksDatabase::addWork failed: %s (db: %s, driver: %s, code: %s)",
                 qPrintable(error.text()),
                 qPrintable(error.databaseText()),
                 qPrintable(error.driverText()),
                 qPrintable(error.nativeErrorCode()));
        return {};
    }

    StringMap result;
    result.insert("id", workId);
    result.insert("object_id", objectId);
    result.insert("service_id", serviceId);
    result.insert("subobject_name", subobjectName);
    result.insert("name", name);
    result.insert("price", price);
    result.insert("unit", unit);
    result.insert("quantity", quantity);
    result.insert("created_at", now);
    result.insert("updated_at", now);
    result.insert("start_order_at", startOrderAt);
    result.insert("coefficients", coefficients);
    result.insert("percent_sum", percentSum);
    return result;
}

StringMapList WorksDatabase::loadWorks(const QString &clientName, const QString &clientId)
{
    createWorksTable(clientName, clientId);
    QSqlDatabase db = openDatabase(clientName, clientId);
    QSqlQuery query(db);
    query.exec(QStringLiteral(
        "SELECT %1 FROM completed_works ORDER BY start_order_at DESC, updated_at DESC")
        .arg(QLatin1String(kWorksSelectColumns)));

    StringMapList result;
    while(query.next())
        result.append(rowToWork(query));
    return result;
}

StringMapList WorksDatabase::loadWorksByObject(const QString &clientName, const QString &clientId, const QString &objectId)
{
    if(objectId.isEmpty())
        return {};

    createWorksTable(clientName, clientId);
    QSqlDatabase db = openDatabase(clientName, clientId);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "SELECT %1 FROM completed_works WHERE object_id = ?"
        " ORDER BY start_order_at DESC, updated_at DESC").arg(QLatin1String(kWorksSelectColumns)));
    query.addBindValue(objectId);
    query.exec();

    StringMapList result;
    while(query.next())
        result.append(rowToWork(query));
    return result;
}

StringMapList WorksDatabase::loadWorksByStartOrder(const QString &clientName, const QString &clientId,
                                             const QString &objectId, qint64 startOrderAt)
{
    if(objectId.isEmpty() || startOrderAt <= 0)
        return {};

    createWorksTable(clientName, clientId);
    QSqlDatabase db = openDatabase(clientName, clientId);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "SELECT %1 FROM completed_works WHERE object_id = ? AND start_order_at = ?"
        " ORDER BY start_order_at DESC, updated_at DESC").arg(QLatin1String(kWorksSelectColumns)));
    query.addBindValue(objectId);
    query.addBindValue(startOrderAt);
    query.exec();

    StringMapList result;
    while(query.next())
        result.append(rowToWork(query));
    return result;
}

StringMapList WorksDatabase::loadWorksBySelectAt(const QString &clientName, const QString &clientId,
                                           const QString &objectId, qint64 startOrderAt)
{
    if(objectId.isEmpty() || startOrderAt <= 0)
        return {};

    createWorksTable(clientName, clientId);
    QSqlDatabase db = openDatabase(clientName, clientId);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "SELECT %1 FROM completed_works WHERE object_id = ? AND start_order_at = ?"
        " ORDER BY updated_at DESC").arg(QLatin1String(kWorksSelectColumns)));
    query.addBindValue(objectId);
    query.addBindValue(startOrderAt);
    query.exec();

    StringMapList result;
    while(query.next())
        result.append(rowToWork(query));
    return result;
}

QStringList WorksDatabase::loadSubobjectNames(const QString &clientName, const QString &clientId, const QString &objectId)
{
    if(objectId.isEmpty())
        return {};

    createWorksTable(clientName, clientId);
    QSqlDatabase db = openDatabase(clientName, clientId);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "SELECT DISTINCT subobject_name FROM completed_works"
        " WHERE object_id = ? AND subobject_name != '' ORDER BY subobject_name"));
    query.addBindValue(objectId);
    query.exec();

    QStringList result;
    while(query.next())
        result.append(query.value(0).toString());
    return result;
}

bool WorksDatabase::deleteWork(const QString &clientName, const QString &clientId, const QString &workId)
{
    if(workId.isEmpty())
        return false;

    QSqlDatabase db = openDatabase(clientName, clientId);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("DELETE FROM completed_works WHERE id = ?"));
    query.addBindValue(workId);
    if(!query.exec())
        return false;

    return query.numRowsAffected() > 0;
}

bool WorksDatabase::updateWork(const QString &clientName, const QString &clientId, const StringMap &data)
{
    if(data.isEmpty())
        return false;

    const QString workId = data.value("id").toString();
    if(workId.isEmpty())
        return false;

    QStringList updates;
    QVariantList params;

    if(data.contains("object_id"))
    {
        updates.append("object_id = ?");
        params.append(data.value("object_id"));
    }
    if(data.contains("service_id"))
    {
        updates.append("service_id = ?");
        params.append(data.value("service_id"));
    }
    if(data.contains("subobject_name"))
    {
        updates.append("subobject_name = ?");
        params.append(notNullText(data.value("subobject_name")));
    }
    if(data.contains("name"))
    {
        const QString name = data.value("name").toString().trimmed();
        if(!name.isEmpty())
        {
            updates.append("name = ?");
            params.append(name);
        }
    }
    if(data.contains("price"))
    {
        updates.append("price = ?");
        params.append(data.value("price").toInt());
    }
    if(data.contains("unit"))
    {
        updates.append("unit = ?");
        params.append(data.value("unit").toString().trimmed());
    }
    if(data.contains("quantity"))
    {
        updates.append("quantity = ?");
        params.append(parseQuantity(data.value("quantity")));
    }
    if(data.contains("start_order_at"))
    {
        updates.append("start_order_at = ?");
        params.append(data.value("start_order_at").toLongLong());
    }
    if(data.contains("coefficients"))
    {
        updates.append("coefficients = ?");
        params.append(notNullText(data.value("coefficients")));
    }
    if(data.contains("percent_sum"))
    {
        updates.append("percent_sum = ?");
        params.append(parsePercentSum(data.value("percent_sum")));
    }

    if(updates.isEmpty())
        return false;

    updates.append("updated_at = ?");
    params.append(QDateTime::currentSecsSinceEpoch());
    params.append(workId);

    QSqlDatabase db = openDatabase(clientName, clientId);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("UPDATE completed_works SET %1 WHERE id = ?").arg(updates.join(", ")));
    for(const QVariant &param : params)
        query.addBindValue(param);

    if(!query.exec())
        return false;

    return query.numRowsAffected() > 0;
}

StringMapList WorksDatabase::getOrders(const QString &clientName, const QString &clientId, const QString &objectId)
{
    QSqlDatabase db = openDatabase(clientName, clientId);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "SELECT start_order_at,"
        " SUM(quantity * price * (percent_sum / 100.0)) AS total_price"
        " FROM completed_works WHERE object_id = ? GROUP BY start_order_at"));
    query.addBindValue(objectId);
    query.exec();

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

StringMapList WorksDatabase::getResultWorks(const QString &clientName, const QString &clientId,
                                      const QStringList &objectIds, const QList<qint64> &ordersAt)
{
    if(ordersAt.isEmpty() || objectIds.isEmpty())
        return {};

    QStringList objectPlaceholders;
    for(int i = 0; i < objectIds.size(); ++i)
        objectPlaceholders.append("?");

    QStringList orderPlaceholders;
    for(int i = 0; i < ordersAt.size(); ++i)
        orderPlaceholders.append("?");

    QSqlDatabase db = openDatabase(clientName, clientId);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "SELECT subobject_name, name, price, unit, quantity, start_order_at, coefficients, percent_sum"
        " FROM completed_works WHERE object_id IN (%1) AND start_order_at IN (%2)"
        " ORDER BY subobject_name").arg(objectPlaceholders.join(", "), orderPlaceholders.join(", ")));

    for(const QString &objectId : objectIds)
        query.addBindValue(objectId);
    for(qint64 orderAt : ordersAt)
        query.addBindValue(orderAt);

    query.exec();

    StringMapList result;
    while(query.next())
        result.append(rowToResult(query));
    return result;
}

int WorksDatabase::mergeFromDatabase(const QString &sourceDbPath,
                                     const QString &clientName,
                                     const QString &clientId)
{
    if(sourceDbPath.isEmpty() || !QFileInfo::exists(sourceDbPath)
       || clientName.isEmpty() || clientId.isEmpty())
    {
        return 0;
    }

    createWorksTable(clientName, clientId);
    const QString srcConn = QStringLiteral("works_merge_src_%1").arg(sourceDbPath);

    int inserted = 0;
    {
        QSqlDatabase src = QSqlDatabase::contains(srcConn)
            ? QSqlDatabase::database(srcConn)
            : QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), srcConn);
        src.setDatabaseName(sourceDbPath);
        if(!src.isOpen() && !src.open())
        {
            qWarning("WorksDatabase::mergeFromDatabase failed to open source: %s",
                     qPrintable(src.lastError().text()));
        }
        else
        {
            QSqlDatabase dst = openDatabase(clientName, clientId);
            QSqlQuery select(src);
            if(!select.exec(QStringLiteral(
                    "SELECT %1 FROM completed_works").arg(QLatin1String(kWorksSelectColumns))))
            {
                qWarning("WorksDatabase::mergeFromDatabase select failed: %s",
                         qPrintable(select.lastError().text()));
            }
            else
            {
                while(select.next())
                {
                    QSqlQuery insert(dst);
                    insert.prepare(QStringLiteral(
                        "INSERT OR IGNORE INTO completed_works ("
                        "id, object_id, service_id, subobject_name, name, price, unit, quantity,"
                        " created_at, updated_at, start_order_at, coefficients, percent_sum"
                        ") VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"));
                    for(int i = 0; i < 13; ++i)
                        insert.addBindValue(select.value(i));
                    if(insert.exec() && insert.numRowsAffected() > 0)
                        ++inserted;
                }
            }
        }
    }

    QSqlDatabase::removeDatabase(srcConn);
    qInfo("WorksDatabase::mergeFromDatabase inserted=%d from %s",
          inserted,
          qPrintable(sourceDbPath));
    return inserted;
}

} // namespace workorder
