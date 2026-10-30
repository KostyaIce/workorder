#include "DatabaseCloudJson.h"

#include "ClientDbDocument.h"
#include "ClientsDatabase.h"
#include "CoefficientsDatabase.h"
#include "DatabaseStorage.h"
#include "ExpensesDatabase.h"
#include "JsonRecordStore.h"
#include "ObjectsDatabase.h"
#include "ServicesDatabase.h"
#include "WorksDatabase.h"

#include <QDir>
#include <QFileInfo>
#include <functional>
#include <QJsonArray>
#include <QJsonObject>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSet>
#include <QVariant>
#include <stdexcept>

namespace workorder
{

namespace
{

class WriteTransaction
{
public:
    explicit WriteTransaction(QSqlDatabase db) : m_db(db)
    {
        if(!m_db.transaction())
            throw std::runtime_error("Failed to start cloud merge transaction");
    }
    ~WriteTransaction() { if(!m_committed) m_db.rollback(); }
    bool commit() { m_committed = m_db.commit(); return m_committed; }
private:
    QSqlDatabase m_db;
    bool m_committed = false;
};

QSqlDatabase openClientsDb(const QString &dbPath)
{
    const QString connectionName = QStringLiteral("cloudjson_clients_%1").arg(dbPath);
    if(QSqlDatabase::contains(connectionName))
        return QSqlDatabase::database(connectionName);

    QDir().mkpath(QFileInfo(dbPath).absolutePath());
    QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), connectionName);
    db.setDatabaseName(dbPath);
    if(!db.open())
        qWarning("DatabaseCloudJson: failed to open clients db %s", qPrintable(dbPath));
    return db;
}

QSqlDatabase openServicesDb(const QString &dbPath)
{
    const QString connectionName = QStringLiteral("cloudjson_services_%1").arg(dbPath);
    if(QSqlDatabase::contains(connectionName))
        return QSqlDatabase::database(connectionName);

    QDir().mkpath(QFileInfo(dbPath).absolutePath());
    QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), connectionName);
    db.setDatabaseName(dbPath);
    if(!db.open())
        qWarning("DatabaseCloudJson: failed to open services db %s", qPrintable(dbPath));
    return db;
}

QSqlDatabase openClientDb(const QString &dbPath, const char *prefix)
{
    const QString connectionName = QString::fromUtf8(prefix) + dbPath;
    if(QSqlDatabase::contains(connectionName))
        return QSqlDatabase::database(connectionName);

    QDir().mkpath(QFileInfo(dbPath).absolutePath());
    QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), connectionName);
    db.setDatabaseName(dbPath);
    if(!db.open())
        qWarning("DatabaseCloudJson: failed to open client db %s", qPrintable(dbPath));
    return db;
}

QJsonArray readClientsArray(const QString &dbPath)
{
    QJsonArray array;
    QSqlDatabase db = openClientsDb(dbPath);
    QSqlQuery query(db);
    if(!query.exec(QStringLiteral(
            "SELECT id, kind, name, address, phone, notes, created_at, updated_at, email FROM clients")))
    {
        throw std::runtime_error("Failed to read clients table");
    }

    while(query.next())
    {
        QJsonObject record;
        record.insert(QStringLiteral("id"), query.value(0).toString());
        record.insert(QStringLiteral("kind"), query.value(1).toString());
        record.insert(QStringLiteral("name"), query.value(2).toString());
        record.insert(QStringLiteral("address"), query.value(3).toString());
        record.insert(QStringLiteral("phone"), query.value(4).toString());
        record.insert(QStringLiteral("email"), query.value(8).toString());
        record.insert(QStringLiteral("notes"), query.value(5).toString());
        record.insert(QStringLiteral("created_at"), query.value(6).toString());
        record.insert(QStringLiteral("updated_at"), query.value(7).toString());
        array.append(record);
    }
    return array;
}

bool writeClientsArray(const QString &dbPath, const QJsonArray &records)
{
    QSqlDatabase db = openClientsDb(dbPath);
    WriteTransaction transaction(db);
    for(const QJsonValue &value : records)
    {
        if(!value.isObject())
            continue;
        const QJsonObject record = value.toObject();
        QSqlQuery query(db);
        query.prepare(QStringLiteral(
            "INSERT INTO clients"
            "(id, kind, name, address, phone, notes, created_at, updated_at, email)"
            " VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?) ON CONFLICT(id) DO UPDATE SET"
            " kind=excluded.kind, name=excluded.name, address=excluded.address,"
            " phone=excluded.phone, email=excluded.email, notes=excluded.notes, created_at=excluded.created_at,"
            " updated_at=excluded.updated_at"));
        query.addBindValue(record.value(QStringLiteral("id")).toString());
        query.addBindValue(record.value(QStringLiteral("kind")).toString());
        query.addBindValue(record.value(QStringLiteral("name")).toString());
        query.addBindValue(record.value(QStringLiteral("address")).toString());
        query.addBindValue(record.value(QStringLiteral("phone")).toString());
        query.addBindValue(record.value(QStringLiteral("notes")).toString());
        query.addBindValue(record.value(QStringLiteral("created_at")).toString());
        query.addBindValue(record.value(QStringLiteral("updated_at")).toString(
            record.value(QStringLiteral("created_at")).toString()));
        query.addBindValue(record.value(QStringLiteral("email")).toString());
        if(!query.exec())
            return false;
    }
    return transaction.commit();
}

QJsonArray readServicesArray(const QString &dbPath)
{
    QJsonArray array;
    QSqlDatabase db = openServicesDb(dbPath);
    QSqlQuery query(db);
    if(!query.exec(QStringLiteral(
            "SELECT id, name, note, paragraph, price, unit, keywords, created_at, updated_at"
            " FROM services")))
    {
        throw std::runtime_error("Failed to read services table");
    }

    while(query.next())
    {
        QJsonObject record;
        record.insert(QStringLiteral("id"), query.value(0).toString());
        record.insert(QStringLiteral("name"), query.value(1).toString());
        record.insert(QStringLiteral("note"), query.value(2).toString());
        record.insert(QStringLiteral("paragraph"), query.value(3).toString());
        record.insert(QStringLiteral("price"), query.value(4).toInt());
        record.insert(QStringLiteral("unit"), query.value(5).toString());
        record.insert(QStringLiteral("keywords"), query.value(6).toString());
        record.insert(QStringLiteral("created_at"), query.value(7).toString());
        record.insert(QStringLiteral("updated_at"), query.value(8).toString());
        array.append(record);
    }
    return array;
}

bool writeServicesArray(const QString &dbPath, const QJsonArray &records)
{
    QSqlDatabase db = openServicesDb(dbPath);
    WriteTransaction transaction(db);
    for(const QJsonValue &value : records)
    {
        if(!value.isObject())
            continue;
        const QJsonObject record = value.toObject();
        QSqlQuery query(db);
        query.prepare(QStringLiteral(
            "INSERT INTO services"
            "(id, name, note, paragraph, price, unit, keywords, created_at, updated_at)"
            " VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?) ON CONFLICT(id) DO UPDATE SET"
            " name=excluded.name, note=excluded.note, paragraph=excluded.paragraph,"
            " price=excluded.price, unit=excluded.unit, keywords=excluded.keywords,"
            " created_at=excluded.created_at, updated_at=excluded.updated_at"));
        query.addBindValue(record.value(QStringLiteral("id")).toString());
        query.addBindValue(record.value(QStringLiteral("name")).toString());
        query.addBindValue(record.value(QStringLiteral("note")).toString());
        query.addBindValue(record.value(QStringLiteral("paragraph")).toString());
        query.addBindValue(record.value(QStringLiteral("price")).toInt());
        query.addBindValue(record.value(QStringLiteral("unit")).toString());
        query.addBindValue(record.value(QStringLiteral("keywords")).toString());
        query.addBindValue(record.value(QStringLiteral("created_at")).toVariant().toString());
        query.addBindValue(record.value(QStringLiteral("updated_at")).toVariant().toString());
        if(!query.exec())
            return false;
    }
    return transaction.commit();
}

QJsonArray readCoefficientsArray(const QString &dbPath)
{
    QJsonArray array;
    QSqlDatabase db = openServicesDb(dbPath);
    QSqlQuery query(db);
    if(!query.exec(QStringLiteral(
            "SELECT id, name, price, unit, keywords, created_at, updated_at"
            " FROM coefficients")))
    {
        throw std::runtime_error("Failed to read coefficients table");
    }

    while(query.next())
    {
        QJsonObject record;
        record.insert(QStringLiteral("id"), query.value(0).toString());
        record.insert(QStringLiteral("name"), query.value(1).toString());
        record.insert(QStringLiteral("price"), query.value(2).toInt());
        record.insert(QStringLiteral("unit"), query.value(3).toString());
        record.insert(QStringLiteral("keywords"), query.value(4).toString());
        record.insert(QStringLiteral("created_at"), query.value(5).toString());
        record.insert(QStringLiteral("updated_at"), query.value(6).toString());
        array.append(record);
    }
    return array;
}

bool writeCoefficientsArray(const QString &dbPath, const QJsonArray &records)
{
    QSqlDatabase db = openServicesDb(dbPath);
    WriteTransaction transaction(db);
    for(const QJsonValue &value : records)
    {
        if(!value.isObject())
            continue;
        const QJsonObject record = value.toObject();
        QSqlQuery query(db);
        query.prepare(QStringLiteral(
            "INSERT INTO coefficients"
            "(id, name, price, unit, keywords, created_at, updated_at)"
            " VALUES (?, ?, ?, ?, ?, ?, ?) ON CONFLICT(id) DO UPDATE SET"
            " name=excluded.name, price=excluded.price, unit=excluded.unit,"
            " keywords=excluded.keywords, created_at=excluded.created_at,"
            " updated_at=excluded.updated_at"));
        query.addBindValue(record.value(QStringLiteral("id")).toString());
        query.addBindValue(record.value(QStringLiteral("name")).toString());
        query.addBindValue(record.value(QStringLiteral("price")).toInt());
        query.addBindValue(record.value(QStringLiteral("unit")).toString());
        query.addBindValue(record.value(QStringLiteral("keywords")).toString());
        query.addBindValue(record.value(QStringLiteral("created_at")).toVariant().toString());
        query.addBindValue(record.value(QStringLiteral("updated_at")).toVariant().toString());
        if(!query.exec())
            return false;
    }
    return transaction.commit();
}

QJsonArray readObjectsArray(const QString &dbPath)
{
    QJsonArray array;
    QSqlDatabase db = openClientDb(dbPath, "cloudjson_objects_");
    QSqlQuery query(db);
    if(!query.exec(QStringLiteral(
            "SELECT id, name, address, updated_at, last_order_at FROM objects")))
    {
        throw std::runtime_error("Failed to read objects table");
    }

    while(query.next())
    {
        QJsonObject record;
        record.insert(QStringLiteral("id"), query.value(0).toString());
        record.insert(QStringLiteral("name"), query.value(1).toString());
        record.insert(QStringLiteral("address"), query.value(2).toString());
        record.insert(QStringLiteral("updated_at"), query.value(3).toLongLong());
        record.insert(QStringLiteral("last_order_at"), query.value(4).toLongLong());
        array.append(record);
    }
    return array;
}

bool writeObjectsArray(const QString &dbPath, const QJsonArray &records)
{
    QSqlDatabase db = openClientDb(dbPath, "cloudjson_objects_");
    WriteTransaction transaction(db);
    for(const QJsonValue &value : records)
    {
        if(!value.isObject())
            continue;
        const QJsonObject record = value.toObject();
        QSqlQuery query(db);
        query.prepare(QStringLiteral(
            "INSERT INTO objects"
            "(id, name, address, updated_at, last_order_at)"
            " VALUES (?, ?, ?, ?, ?) ON CONFLICT(id) DO UPDATE SET"
            " name=excluded.name, address=excluded.address, updated_at=excluded.updated_at,"
            " last_order_at=excluded.last_order_at"));
        query.addBindValue(record.value(QStringLiteral("id")).toString());
        query.addBindValue(record.value(QStringLiteral("name")).toString());
        query.addBindValue(record.value(QStringLiteral("address")).toString());
        query.addBindValue(record.value(QStringLiteral("updated_at")).toVariant().toLongLong());
        query.addBindValue(record.value(QStringLiteral("last_order_at")).toVariant().toLongLong());
        if(!query.exec())
            return false;
    }
    return transaction.commit();
}

QJsonArray readWorksArray(const QString &dbPath)
{
    QJsonArray array;
    QSqlDatabase db = openClientDb(dbPath, "cloudjson_works_");
    QSqlQuery query(db);
    if(!query.exec(QStringLiteral(
            "SELECT id, object_id, service_id, subobject_name, name, price, unit, quantity,"
            " created_at, updated_at, start_order_at, coefficients, percent_sum"
            " FROM completed_works")))
    {
        throw std::runtime_error("Failed to read completed_works table");
    }

    while(query.next())
    {
        QJsonObject record;
        record.insert(QStringLiteral("id"), query.value(0).toString());
        record.insert(QStringLiteral("object_id"), query.value(1).toString());
        record.insert(QStringLiteral("service_id"), query.value(2).toString());
        record.insert(QStringLiteral("subobject_name"), query.value(3).toString());
        record.insert(QStringLiteral("name"), query.value(4).toString());
        record.insert(QStringLiteral("price"), query.value(5).toInt());
        record.insert(QStringLiteral("unit"), query.value(6).toString());
        record.insert(QStringLiteral("quantity"), query.value(7).toDouble());
        record.insert(QStringLiteral("created_at"), query.value(8).toLongLong());
        record.insert(QStringLiteral("updated_at"), query.value(9).toLongLong());
        record.insert(QStringLiteral("start_order_at"), query.value(10).toLongLong());
        record.insert(QStringLiteral("coefficients"), query.value(11).toString());
        record.insert(QStringLiteral("percent_sum"), query.value(12).toInt());
        array.append(record);
    }
    return array;
}

bool writeWorksArray(const QString &dbPath, const QJsonArray &records)
{
    QSqlDatabase db = openClientDb(dbPath, "cloudjson_works_");
    WriteTransaction transaction(db);
    for(const QJsonValue &value : records)
    {
        if(!value.isObject())
            continue;
        const QJsonObject record = value.toObject();
        QSqlQuery query(db);
        query.prepare(QStringLiteral(
            "INSERT INTO completed_works ("
            "id, object_id, service_id, subobject_name, name, price, unit, quantity,"
            " created_at, updated_at, start_order_at, coefficients, percent_sum"
            ") VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) ON CONFLICT(id) DO UPDATE SET"
            " object_id=excluded.object_id, service_id=excluded.service_id,"
            " subobject_name=excluded.subobject_name, name=excluded.name, price=excluded.price,"
            " unit=excluded.unit, quantity=excluded.quantity, created_at=excluded.created_at,"
            " updated_at=excluded.updated_at, start_order_at=excluded.start_order_at,"
            " coefficients=excluded.coefficients, percent_sum=excluded.percent_sum"));
        query.addBindValue(record.value(QStringLiteral("id")).toString());
        query.addBindValue(record.value(QStringLiteral("object_id")).toString());
        query.addBindValue(record.value(QStringLiteral("service_id")).toString());
        query.addBindValue(record.value(QStringLiteral("subobject_name")).toString());
        query.addBindValue(record.value(QStringLiteral("name")).toString());
        query.addBindValue(record.value(QStringLiteral("price")).toInt());
        query.addBindValue(record.value(QStringLiteral("unit")).toString());
        query.addBindValue(record.value(QStringLiteral("quantity")).toDouble());
        query.addBindValue(record.value(QStringLiteral("created_at")).toVariant().toLongLong());
        query.addBindValue(record.value(QStringLiteral("updated_at")).toVariant().toLongLong());
        query.addBindValue(record.value(QStringLiteral("start_order_at")).toVariant().toLongLong());
        query.addBindValue(record.value(QStringLiteral("coefficients")).toString());
        query.addBindValue(record.value(QStringLiteral("percent_sum")).toInt());
        if(!query.exec())
            return false;
    }
    return transaction.commit();
}

QJsonArray readExpensesArray(const QString &dbPath)
{
    QJsonArray array;
    QSqlDatabase db = openClientDb(dbPath, "cloudjson_expenses_");
    QSqlQuery query(db);
    if(!query.exec(QStringLiteral(
            "SELECT id, object_id, start_order_at, description, amount, created_at, updated_at"
            " FROM expenses")))
    {
        throw std::runtime_error("Failed to read expenses table");
    }

    while(query.next())
    {
        QJsonObject record;
        record.insert(QStringLiteral("id"), query.value(0).toString());
        record.insert(QStringLiteral("object_id"), query.value(1).toString());
        record.insert(QStringLiteral("start_order_at"), query.value(2).toLongLong());
        record.insert(QStringLiteral("description"), query.value(3).toString());
        record.insert(QStringLiteral("amount"), query.value(4).toInt());
        record.insert(QStringLiteral("created_at"), query.value(5).toLongLong());
        record.insert(QStringLiteral("updated_at"), query.value(6).toLongLong());
        array.append(record);
    }
    return array;
}

bool writeExpensesArray(const QString &dbPath, const QJsonArray &records)
{
    QSqlDatabase db = openClientDb(dbPath, "cloudjson_expenses_");
    WriteTransaction transaction(db);
    for(const QJsonValue &value : records)
    {
        if(!value.isObject())
            continue;
        const QJsonObject record = value.toObject();
        QSqlQuery query(db);
        query.prepare(QStringLiteral(
            "INSERT INTO expenses"
            "(id, object_id, start_order_at, description, amount, created_at, updated_at)"
            " VALUES (?, ?, ?, ?, ?, ?, ?) ON CONFLICT(id) DO UPDATE SET"
            " object_id=excluded.object_id, start_order_at=excluded.start_order_at,"
            " description=excluded.description, amount=excluded.amount,"
            " created_at=excluded.created_at, updated_at=excluded.updated_at"));
        query.addBindValue(record.value(QStringLiteral("id")).toString());
        query.addBindValue(record.value(QStringLiteral("object_id")).toString());
        query.addBindValue(record.value(QStringLiteral("start_order_at")).toVariant().toLongLong());
        query.addBindValue(record.value(QStringLiteral("description")).toString());
        query.addBindValue(record.value(QStringLiteral("amount")).toInt());
        query.addBindValue(record.value(QStringLiteral("created_at")).toVariant().toLongLong());
        query.addBindValue(record.value(QStringLiteral("updated_at")).toVariant().toLongLong());
        if(!query.exec())
            return false;
    }
    return transaction.commit();
}

int mergeArrayIntoSqlite(const QJsonArray &localRecords,
                         const QJsonArray &remoteRecords,
                         const std::function<bool(const QJsonArray &)> &writer)
{
    const JsonMergeResult mergeResult = JsonRecordStore::mergeByLatestRevision(localRecords, remoteRecords);
    if(!writer(mergeResult.merged))
        return -1;
    return mergeResult.added;
}

} // namespace

int DatabaseCloudJson::mergeClientsFromJsonFile(const QString &jsonPath, const QString &dbPath)
{
    if(jsonPath.isEmpty() || !QFileInfo::exists(jsonPath))
        return 0;

    const QString targetPath = dbPath.isEmpty() ? DatabaseStorage::defaultClientsDbPath() : dbPath;
    ClientsDatabase::createClientTable(targetPath);

    const QJsonObject remoteDocument = JsonRecordStore::loadDocument(jsonPath);
    const QJsonArray remoteRecords = remoteDocument.value(QStringLiteral("clients")).toArray();
    const QJsonArray localRecords = readClientsArray(targetPath);
    const int added = mergeArrayIntoSqlite(localRecords, remoteRecords, [&](const QJsonArray &merged)
    {
        return writeClientsArray(targetPath, merged);
    });
    qInfo("DatabaseCloudJson::mergeClientsFromJsonFile added=%d from %s",
          added,
          qPrintable(jsonPath));
    return added;
}

bool DatabaseCloudJson::exportClientsToJsonFile(const QString &dbPath, const QString &jsonPath)
{
    const QString sourcePath = dbPath.isEmpty() ? DatabaseStorage::defaultClientsDbPath() : dbPath;
    ClientsDatabase::createClientTable(sourcePath);

    QJsonObject document;
    document.insert(QStringLiteral("clients"), readClientsArray(sourcePath));
    return JsonRecordStore::saveDocument(jsonPath, document);
}

int DatabaseCloudJson::mergeServicesFromJsonFile(const QString &jsonPath)
{
    if(jsonPath.isEmpty() || !QFileInfo::exists(jsonPath))
        return 0;

    ServicesDatabase::createServicesTable();
    CoefficientsDatabase::createCoefficientsTable();
    const QString targetPath = ServicesDatabase::defaultServicesDbPath();
    const QJsonObject remoteDocument = JsonRecordStore::loadDocument(jsonPath);

    const int addedServices = mergeArrayIntoSqlite(
        readServicesArray(targetPath),
        remoteDocument.value(QStringLiteral("services")).toArray(),
        [&](const QJsonArray &merged)
        {
            return writeServicesArray(targetPath, merged);
        });
    if(addedServices < 0)
        return -1;

    // Coefficients share the services.json document but have their own table.
    const int addedCoefficients = mergeArrayIntoSqlite(
        readCoefficientsArray(targetPath),
        remoteDocument.value(QStringLiteral("coefficients")).toArray(),
        [&](const QJsonArray &merged)
        {
            return writeCoefficientsArray(targetPath, merged);
        });
    if(addedCoefficients < 0)
        return -1;

    qInfo("DatabaseCloudJson::mergeServicesFromJsonFile added services=%d coefficients=%d from %s",
          addedServices,
          addedCoefficients,
          qPrintable(jsonPath));
    return addedServices + addedCoefficients;
}

bool DatabaseCloudJson::exportServicesToJsonFile(const QString &jsonPath)
{
    ServicesDatabase::createServicesTable();
    CoefficientsDatabase::createCoefficientsTable();
    const QString sourcePath = ServicesDatabase::defaultServicesDbPath();
    QJsonObject document;
    document.insert(QStringLiteral("services"), readServicesArray(sourcePath));
    document.insert(QStringLiteral("coefficients"), readCoefficientsArray(sourcePath));
    return JsonRecordStore::saveDocument(jsonPath, document);
}

int DatabaseCloudJson::mergeClientDbFromJsonFile(const QString &jsonPath,
                                                 const QString &clientName,
                                                 const QString &clientId)
{
    if(jsonPath.isEmpty() || !QFileInfo::exists(jsonPath)
       || clientName.isEmpty() || clientId.isEmpty())
    {
        return 0;
    }

    ObjectsDatabase::createObjectDatabase(clientName, clientId);
    WorksDatabase::createWorksTable(clientName, clientId);
    ExpensesDatabase::createExpensesTable(clientName, clientId);

    const QJsonObject remoteDocument = ClientDbDocument::loadFile(jsonPath);
    const QString dbPath = DatabaseStorage::objectDbPath(clientName, clientId);

    int added = mergeArrayIntoSqlite(readObjectsArray(dbPath),
                                     ClientDbDocument::objectsArray(remoteDocument),
                                     [&](const QJsonArray &merged)
                                     {
                                         return writeObjectsArray(dbPath, merged);
                                     });
    if(added < 0)
        return -1;

    const int worksAdded = mergeArrayIntoSqlite(readWorksArray(dbPath),
                                                ClientDbDocument::worksArray(remoteDocument),
                                                [&](const QJsonArray &merged)
                                                {
                                                    return writeWorksArray(dbPath, merged);
                                                });
    if(worksAdded < 0)
        return -1;
    added += worksAdded;

    const int expensesAdded = mergeArrayIntoSqlite(readExpensesArray(dbPath),
                                                   ClientDbDocument::expensesArray(remoteDocument),
                                                   [&](const QJsonArray &merged)
                                                   {
                                                       return writeExpensesArray(dbPath, merged);
                                                   });
    if(expensesAdded < 0)
        return -1;
    added += expensesAdded;

    qInfo("DatabaseCloudJson::mergeClientDbFromJsonFile added=%d from %s",
          added,
          qPrintable(jsonPath));
    return added;
}

bool DatabaseCloudJson::exportClientDbToJsonFile(const QString &clientName,
                                                 const QString &clientId,
                                                 const QString &jsonPath)
{
    if(clientName.isEmpty() || clientId.isEmpty())
        return false;

    ObjectsDatabase::createObjectDatabase(clientName, clientId);
    WorksDatabase::createWorksTable(clientName, clientId);
    ExpensesDatabase::createExpensesTable(clientName, clientId);

    const QString dbPath = DatabaseStorage::objectDbPath(clientName, clientId);
    QJsonObject document = ClientDbDocument::emptyDocument();
    document.insert(QStringLiteral("objects"), readObjectsArray(dbPath));
    document.insert(QStringLiteral("completed_works"), readWorksArray(dbPath));
    document.insert(QStringLiteral("expenses"), readExpensesArray(dbPath));
    return JsonRecordStore::saveDocument(jsonPath, document);
}

} // namespace workorder
