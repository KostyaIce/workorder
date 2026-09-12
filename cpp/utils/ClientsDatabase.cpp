#include "ClientsDatabase.h"

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

QSqlDatabase openDatabase(const QString &dbPath)
{
    const QString connectionName = QStringLiteral("clients_%1").arg(dbPath);
    if(QSqlDatabase::contains(connectionName))
        return QSqlDatabase::database(connectionName);

    QDir().mkpath(QFileInfo(dbPath).absolutePath());

    QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), connectionName);
    db.setDatabaseName(dbPath);
    if(!db.open())
        qWarning("Failed to open clients database: %s", qPrintable(db.lastError().text()));

    return db;
}

} // namespace

QString ClientsDatabase::resolveDbPath(const QString &dbPath)
{
    if(dbPath.isEmpty())
        return DatabaseStorage::defaultClientsDbPath();
    return dbPath;
}

void ClientsDatabase::createClientTable(const QString &dbPath)
{
    const QString path = resolveDbPath(dbPath);
    QSqlDatabase db = openDatabase(path);
    QSqlQuery query(db);
    query.exec(QStringLiteral(
        "CREATE TABLE IF NOT EXISTS clients ("
        "id TEXT PRIMARY KEY,"
        "kind TEXT NOT NULL,"
        "name TEXT NOT NULL,"
        "address TEXT,"
        "contact TEXT,"
        "notes TEXT,"
        "created_at TEXT,"
        "UNIQUE (name, address, contact)"
        ")"));
}

bool ClientsDatabase::addClientEntry(const StringMap &data, const QString &dbPath)
{
    if(data.isEmpty())
        return false;

    createClientTable(dbPath);
    const QString path = resolveDbPath(dbPath);
    QSqlDatabase db = openDatabase(path);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "INSERT INTO clients(id, kind, name, address, contact, notes, created_at)"
        " VALUES (?, ?, ?, ?, ?, ?, ?)"));
    query.addBindValue(QUuid::createUuid().toString(QUuid::WithoutBraces));
    query.addBindValue(data.value("kind"));
    query.addBindValue(data.value("name"));
    query.addBindValue(data.value("address", QString()));
    query.addBindValue(data.value("contact", QString()));
    query.addBindValue(data.value("notes", QString()));
    query.addBindValue(QDateTime::currentDateTime().toString(Qt::ISODate));

    if(!query.exec())
    {
        qWarning("Failed to add client: %s", qPrintable(query.lastError().text()));
        return false;
    }

    return query.numRowsAffected() > 0;
}

bool ClientsDatabase::updateClientEntry(const StringMap &data, const QString &dbPath)
{
    if(data.isEmpty())
        return false;

    const QString clientId = data.value("id").toString();
    if(clientId.isEmpty())
        return false;

    createClientTable(dbPath);
    const QString path = resolveDbPath(dbPath);
    QSqlDatabase db = openDatabase(path);
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "UPDATE clients SET name = ?, address = ?, contact = ?, notes = ? WHERE id = ?"));
    query.addBindValue(data.value("name"));
    query.addBindValue(data.value("address", QString()));
    query.addBindValue(data.value("contact", QString()));
    query.addBindValue(data.value("notes", QString()));
    query.addBindValue(clientId);

    if(!query.exec())
    {
        qWarning("Failed to update client: %s", qPrintable(query.lastError().text()));
        return false;
    }

    return query.numRowsAffected() > 0;
}

StringMapList ClientsDatabase::loadClients(const QString &dbPath)
{
    const QString path = resolveDbPath(dbPath);
    if(!QFileInfo::exists(path))
        return {};

    QSqlDatabase db = openDatabase(path);
    QSqlQuery query(db);
    query.exec(QStringLiteral(
        "SELECT id, kind, name, contact, address, notes, created_at"
        " FROM clients ORDER BY id"));

    StringMapList result;
    while(query.next())
    {
        StringMap row;
        row.insert("id", query.value(0));
        row.insert("kind", query.value(1));
        row.insert("name", query.value(2));
        row.insert("contact_info", query.value(3));
        row.insert("address", query.value(4));
        row.insert("notes", query.value(5));
        row.insert("created_at", query.value(6));
        result.append(row);
    }
    return result;
}

bool ClientsDatabase::delClientEntry(const StringMap &data, const QString &dbPath)
{
    if(data.isEmpty())
        return false;

    const QString clientId = data.value("id").toString();
    if(clientId.isEmpty())
        return false;

    const QString path = resolveDbPath(dbPath);
    QSqlDatabase db = openDatabase(path);
    QSqlQuery query(db);
    query.prepare(QStringLiteral("DELETE FROM clients WHERE id = ?"));
    query.addBindValue(clientId);
    return query.exec();
}

int ClientsDatabase::mergeFromDatabase(const QString &sourceDbPath, const QString &targetDbPath)
{
    if(sourceDbPath.isEmpty() || !QFileInfo::exists(sourceDbPath))
        return 0;

    createClientTable(targetDbPath);
    const QString targetPath = resolveDbPath(targetDbPath);
    const QString srcConn = QStringLiteral("clients_merge_src_%1").arg(sourceDbPath);

    int inserted = 0;
    {
        QSqlDatabase src = QSqlDatabase::contains(srcConn)
            ? QSqlDatabase::database(srcConn)
            : QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), srcConn);
        src.setDatabaseName(sourceDbPath);
        if(!src.isOpen() && !src.open())
        {
            qWarning("ClientsDatabase::mergeFromDatabase failed to open source: %s",
                     qPrintable(src.lastError().text()));
        }
        else
        {
            QSqlDatabase dst = openDatabase(targetPath);
            QSqlQuery select(src);
            if(!select.exec(QStringLiteral(
                    "SELECT id, kind, name, address, contact, notes, created_at FROM clients")))
            {
                qWarning("ClientsDatabase::mergeFromDatabase select failed: %s",
                         qPrintable(select.lastError().text()));
            }
            else
            {
                while(select.next())
                {
                    QSqlQuery insert(dst);
                    insert.prepare(QStringLiteral(
                        "INSERT OR IGNORE INTO clients"
                        "(id, kind, name, address, contact, notes, created_at)"
                        " VALUES (?, ?, ?, ?, ?, ?, ?)"));
                    insert.addBindValue(select.value(0));
                    insert.addBindValue(select.value(1));
                    insert.addBindValue(select.value(2));
                    insert.addBindValue(select.value(3));
                    insert.addBindValue(select.value(4));
                    insert.addBindValue(select.value(5));
                    insert.addBindValue(select.value(6));
                    if(insert.exec() && insert.numRowsAffected() > 0)
                        ++inserted;
                }
            }
        }
    }

    QSqlDatabase::removeDatabase(srcConn);
    qInfo("ClientsDatabase::mergeFromDatabase inserted=%d from %s",
          inserted,
          qPrintable(sourceDbPath));
    return inserted;
}

} // namespace workorder
