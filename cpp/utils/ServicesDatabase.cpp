#include "ServicesDatabase.h"

#include "AppPaths.h"

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

const QSet<QString> kServicesColumns = {
    "id", "name", "note", "paragraph", "price", "unit", "keywords", "created_at", "updated_at",
};

QSqlDatabase openDatabase()
{
    static const QString connectionName = QStringLiteral("services");
    if(QSqlDatabase::contains(connectionName))
        return QSqlDatabase::database(connectionName);

    const QString dbPath = ServicesDatabase::defaultServicesDbPath();
    QDir().mkpath(QFileInfo(dbPath).absolutePath());

    QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), connectionName);
    db.setDatabaseName(dbPath);
    if(!db.open())
        qWarning("Failed to open services database: %s", qPrintable(db.lastError().text()));

    return db;
}

QSet<QString> tableColumns(QSqlDatabase &db)
{
    QSet<QString> columns;
    QSqlQuery query(db);
    query.exec(QStringLiteral("PRAGMA table_info(services)"));
    while(query.next())
        columns.insert(query.value(1).toString());
    return columns;
}

StringMap rowToService(const QSqlQuery &query)
{
    StringMap row;
    row.insert("id", query.value(0));
    row.insert("name", query.value(1));
    row.insert("note", query.value(2));
    row.insert("paragraph", query.value(3));
    row.insert("price", query.value(4));
    row.insert("unit", query.value(5));
    row.insert("keywords", query.value(6));
    row.insert("created_at", query.value(7));
    row.insert("updated_at", query.value(8));
    return row;
}

} // namespace

QString ServicesDatabase::defaultServicesDbPath()
{
    return QDir(AppPaths::projectDataDir()).filePath("services.db");
}

int ServicesDatabase::parsePriceCents(const QVariant &value)
{
    QString text = value.toString().trimmed().replace(',', '.');
    if(text.isEmpty())
        return 0;

    bool ok = false;
    const double amount = text.toDouble(&ok);
    if(!ok)
        return 0;

    return static_cast<int>(qRound64(amount * 100.0));
}

QString ServicesDatabase::keywordsFromName(const QString &name)
{
    const QStringList words = name.split(' ', Qt::SkipEmptyParts);
    QStringList filtered;
    for(const QString &word : words)
    {
        if(word.size() > 2)
            filtered.append(word.toLower());
    }

    if(filtered.isEmpty())
        return name.toLower();

    return filtered.join(", ");
}

void ServicesDatabase::createServicesTable()
{
    QSqlDatabase db = openDatabase();
    const QSet<QString> columns = tableColumns(db);
    if(!columns.isEmpty() && columns != kServicesColumns)
    {
        qWarning("services table schema mismatch, recreating table");
        QSqlQuery(db).exec(QStringLiteral("DROP TABLE services"));
    }

    QSqlQuery query(db);
    query.exec(QStringLiteral(
        "CREATE TABLE IF NOT EXISTS services ("
        "id TEXT PRIMARY KEY,"
        "name TEXT NOT NULL UNIQUE,"
        "note TEXT,"
        "paragraph TEXT,"
        "price INTEGER NOT NULL,"
        "unit TEXT,"
        "keywords TEXT,"
        "created_at TEXT NOT NULL,"
        "updated_at TEXT NOT NULL"
        ")"));
}

bool ServicesDatabase::addService(const StringMap &data)
{
    if(data.isEmpty())
        return false;

    const QString name = data.value("name").toString().trimmed();
    if(name.isEmpty())
        return false;

    const QString serviceId = QUuid::createUuid().toString(QUuid::WithoutBraces);
    const int price = parsePriceCents(data.value("price"));
    const QString note = data.value("note").toString().trimmed();
    const QString paragraph = data.value("paragraph").toString().trimmed();
    const QString unit = data.value("unit").toString().trimmed();
    QString keywords = data.value("keywords").toString().trimmed();
    if(keywords.isEmpty())
        keywords = keywordsFromName(name);

    const QString now = QDateTime::currentDateTime().toString(Qt::ISODate);

    createServicesTable();
    QSqlDatabase db = openDatabase();
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "INSERT INTO services ("
        "id, name, note, paragraph, price, unit, keywords, created_at, updated_at"
        ") VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)"));
    query.addBindValue(serviceId);
    query.addBindValue(name);
    query.addBindValue(note);
    query.addBindValue(paragraph);
    query.addBindValue(price);
    query.addBindValue(unit);
    query.addBindValue(keywords);
    query.addBindValue(now);
    query.addBindValue(now);

    if(!query.exec())
    {
        qWarning("Service already exists: %s", qPrintable(name));
        return false;
    }

    return true;
}

bool ServicesDatabase::deleteService(const QString &serviceId)
{
    if(serviceId.isEmpty())
        return false;

    QSqlDatabase db = openDatabase();
    QSqlQuery query(db);
    query.prepare(QStringLiteral("DELETE FROM services WHERE id = ?"));
    query.addBindValue(serviceId);
    if(!query.exec())
        return false;

    return query.numRowsAffected() > 0;
}

bool ServicesDatabase::updateService(const StringMap &data)
{
    if(data.isEmpty())
        return false;

    const QString name = data.value("name").toString().trimmed();
    if(name.isEmpty())
        return false;

    const QString serviceId = data.value("id").toString().trimmed();
    if(serviceId.isEmpty())
        return false;

    const int price = parsePriceCents(data.value("price"));
    const QString note = data.value("note").toString().trimmed();
    const QString paragraph = data.value("paragraph").toString().trimmed();
    const QString unit = data.value("unit").toString().trimmed();
    QString keywords = data.value("keywords").toString().trimmed();
    if(keywords.isEmpty())
        keywords = keywordsFromName(name);

    const QString now = QDateTime::currentDateTime().toString(Qt::ISODate);

    QSqlDatabase db = openDatabase();
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "UPDATE services SET name = ?, note = ?, paragraph = ?, price = ?, unit = ?, keywords = ?, updated_at = ?"
        " WHERE id = ?"));
    query.addBindValue(name);
    query.addBindValue(note);
    query.addBindValue(paragraph);
    query.addBindValue(price);
    query.addBindValue(unit);
    query.addBindValue(keywords);
    query.addBindValue(now);
    query.addBindValue(serviceId);

    if(!query.exec())
    {
        qWarning("Service name already exists: %s", qPrintable(name));
        return false;
    }

    return query.numRowsAffected() > 0;
}

StringMapList ServicesDatabase::loadServices()
{
    createServicesTable();
    QSqlDatabase db = openDatabase();
    QSqlQuery query(db);
    query.exec(QStringLiteral(
        "SELECT id, name, note, paragraph, price, unit, keywords, created_at, updated_at"
        " FROM services ORDER BY name"));

    StringMapList result;
    while(query.next())
        result.append(rowToService(query));
    return result;
}

StringMap ServicesDatabase::getServiceById(const QString &serviceId)
{
    QSqlDatabase db = openDatabase();
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "SELECT id, name, note, paragraph, price, unit, keywords, created_at, updated_at"
        " FROM services WHERE id = ?"));
    query.addBindValue(serviceId);
    query.exec();

    if(query.next())
        return rowToService(query);

    return {};
}

StringMapList ServicesDatabase::searchServices(const QString &queryText)
{
    if(queryText.trimmed().isEmpty())
        return loadServices();

    const QString pattern = QStringLiteral("%%1%").arg(queryText.trimmed());
    QSqlDatabase db = openDatabase();
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "SELECT id, name, note, paragraph, price, unit, keywords, created_at, updated_at"
        " FROM services WHERE name LIKE ? OR keywords LIKE ? ORDER BY name"));
    query.addBindValue(pattern);
    query.addBindValue(pattern);
    query.exec();

    StringMapList result;
    while(query.next())
        result.append(rowToService(query));
    return result;
}

} // namespace workorder
