#include "ObjectsDatabase.h"

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

QString connectionName(const QString &clientName, const QString &clientId)
{
    return QStringLiteral("objects_%1_%2").arg(clientName, clientId);
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
        qWarning("Failed to open objects database: %s", qPrintable(db.lastError().text()));

    return db;
}

} // namespace

void ObjectsDatabase::createObjectDatabase(const QString &clientName, const QString &clientId)
{
    QSqlDatabase db = openDatabase(clientName, clientId);
    QSqlQuery query(db);
    query.exec(QStringLiteral(
        "CREATE TABLE IF NOT EXISTS objects ("
        "id TEXT PRIMARY KEY,"
        "name TEXT NOT NULL,"
        "address TEXT NOT NULL DEFAULT '',"
        "updated_at INTEGER NOT NULL,"
        "last_order_at INTEGER NOT NULL DEFAULT 0"
        ")"));
}

bool ObjectsDatabase::addObjectEntry(const QString &clientName, const QString &clientId,
                               const QString &name, const QString &address)
{
    createObjectDatabase(clientName, clientId);
    QSqlDatabase db = openDatabase(clientName, clientId);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "INSERT INTO objects(id, name, address, updated_at, last_order_at)"
        " VALUES (?, ?, ?, ?, ?)"));
    query.addBindValue(QUuid::createUuid().toString(QUuid::WithoutBraces));
    query.addBindValue(name);
    query.addBindValue(address);
    query.addBindValue(QDateTime::currentSecsSinceEpoch());
    query.addBindValue(0);

    if(!query.exec())
        return false;

    return query.numRowsAffected() > 0;
}

StringMapList ObjectsDatabase::loadObjects(const QString &clientName, const QString &clientId)
{
    const QString dbPath = DatabaseStorage::objectDbPath(clientName, clientId);
    if(!QFileInfo::exists(dbPath))
        return {};

    createObjectDatabase(clientName, clientId);
    QSqlDatabase db = openDatabase(clientName, clientId);
    QSqlQuery query(db);
    query.exec(QStringLiteral(
        "SELECT id, name, address, updated_at, last_order_at"
        " FROM objects ORDER BY updated_at"));

    StringMapList result;
    while(query.next())
    {
        StringMap row;
        row.insert("id", query.value(0));
        row.insert("name", query.value(1));
        row.insert("address", query.value(2));
        row.insert("updated_at", query.value(3));
        row.insert("last_order_at", query.value(4));
        result.append(row);
    }
    return result;
}

bool ObjectsDatabase::delObjectEntry(const QString &clientName, const QString &clientId, const StringMap &data)
{
    if(data.isEmpty())
        return false;

    const QString objectId = data.value("id").toString();
    QSqlDatabase db = openDatabase(clientName, clientId);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("DELETE FROM objects WHERE id = ?"));
    query.addBindValue(objectId);
    return query.exec();
}

bool ObjectsDatabase::updateObjectName(const QString &clientName, const QString &clientId, const StringMap &data)
{
    if(data.isEmpty())
        return false;

    QSqlDatabase db = openDatabase(clientName, clientId);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "UPDATE objects SET updated_at = ?, name = ?, address = ? WHERE id = ?"));
    query.addBindValue(QDateTime::currentSecsSinceEpoch());
    query.addBindValue(data.value("name"));
    query.addBindValue(data.value("address", QString()));
    query.addBindValue(data.value("id"));

    if(!query.exec())
        return false;

    return query.numRowsAffected() > 0;
}

bool ObjectsDatabase::updateObjectLastOrderAt(const QString &clientName, const QString &clientId, const QString &objectId)
{
    if(objectId.isEmpty())
        return false;

    QSqlDatabase db = openDatabase(clientName, clientId);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("UPDATE objects SET last_order_at = ? WHERE id = ?"));
    query.addBindValue(QDateTime::currentSecsSinceEpoch());
    query.addBindValue(objectId);

    if(!query.exec())
        return false;

    return query.numRowsAffected() > 0;
}

} // namespace workorder
