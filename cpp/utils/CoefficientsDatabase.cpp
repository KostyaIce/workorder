#include "CoefficientsDatabase.h"

#include "AppPaths.h"
#include "ServiceUnits.h"
#include "ServicesDatabase.h"

#include <QDateTime>
#include <QDir>
#include <QFileInfo>
#include <QSet>
#include <QStringList>
#include <QSqlDatabase>
#include <QSqlError>
#include <QSqlQuery>
#include <QUuid>

namespace workorder
{

namespace
{

const QSet<QString> kCoefficientColumns = {
    "id", "name", "price", "unit", "keywords", "created_at", "updated_at",
};

QSqlDatabase openDatabase()
{
    // Coefficients share the services.db file, so reuse its connection.
    static const QString connectionName = QStringLiteral("services");
    if(QSqlDatabase::contains(connectionName))
        return QSqlDatabase::database(connectionName);

    const QString dbPath = CoefficientsDatabase::defaultCoefficientsDbPath();
    QDir().mkpath(QFileInfo(dbPath).absolutePath());

    QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), connectionName);
    db.setDatabaseName(dbPath);
    if(!db.open())
        qWarning("Failed to open coefficients database: %s", qPrintable(db.lastError().text()));

    return db;
}

QSet<QString> tableColumns(QSqlDatabase &db)
{
    QSet<QString> columns;
    QSqlQuery query(db);
    query.exec(QStringLiteral("PRAGMA table_info(coefficients)"));
    while(query.next())
        columns.insert(query.value(1).toString());
    return columns;
}

StringMap rowToCoefficient(const QSqlQuery &query)
{
    StringMap row;
    row.insert("id", query.value(0));
    row.insert("name", query.value(1));
    row.insert("price", query.value(2));
    row.insert("unit", query.value(3));
    row.insert("keywords", query.value(4));
    row.insert("created_at", query.value(5));
    row.insert("updated_at", query.value(6));
    return row;
}

const char *kCoefficientUnit = "%";

const QStringList kCoefficientColumnsOrder = {
    "id", "name", "price", "unit", "keywords", "created_at", "updated_at",
};

} // namespace

QString CoefficientsDatabase::defaultCoefficientsDbPath()
{
    return ServicesDatabase::defaultServicesDbPath();
}

int CoefficientsDatabase::parsePriceCents(const QVariant &value)
{
    return ServicesDatabase::parsePriceCents(value);
}

QString CoefficientsDatabase::keywordsFromName(const QString &name)
{
    return ServicesDatabase::keywordsFromName(name);
}

void CoefficientsDatabase::createCoefficientsTable()
{
    QSqlDatabase db = openDatabase();
    const QSet<QString> columns = tableColumns(db);
    if(!columns.isEmpty() && columns != kCoefficientColumns)
    {
        qWarning("coefficients table schema mismatch, recreating table");
        QSqlQuery(db).exec(QStringLiteral("DROP TABLE coefficients"));
    }

    QSqlQuery query(db);
    query.exec(QStringLiteral(
        "CREATE TABLE IF NOT EXISTS coefficients ("
        "id TEXT PRIMARY KEY,"
        "name TEXT NOT NULL UNIQUE,"
        "price INTEGER NOT NULL,"
        "unit TEXT NOT NULL DEFAULT '%',"
        "keywords TEXT,"
        "created_at TEXT NOT NULL,"
        "updated_at TEXT NOT NULL"
        ")"));

    migratePercentServices();
}

QString CoefficientsDatabase::addCoefficient(const StringMap &data)
{
    if(data.isEmpty())
        return {};

    const QString name = data.value("name").toString().trimmed();
    if(name.isEmpty())
        return {};

    createCoefficientsTable();

    const QString coefficientId = QUuid::createUuid().toString(QUuid::WithoutBraces);
    const int price = parsePriceCents(data.value("price"));
    QString unit = data.value("unit").toString().trimmed();
    if(unit.isEmpty())
        unit = QString::fromUtf8(kCoefficientUnit);
    QString keywords = data.value("keywords").toString().trimmed();
    if(keywords.isEmpty())
        keywords = keywordsFromName(name);

    const QString now = QDateTime::currentDateTime().toString(Qt::ISODate);

    QSqlDatabase db = openDatabase();
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "INSERT INTO coefficients ("
        "id, name, price, unit, keywords, created_at, updated_at"
        ") VALUES (?, ?, ?, ?, ?, ?, ?)"));
    query.addBindValue(coefficientId);
    query.addBindValue(name);
    query.addBindValue(price);
    query.addBindValue(unit);
    query.addBindValue(keywords);
    query.addBindValue(now);
    query.addBindValue(now);

    if(!query.exec())
    {
        qWarning("Coefficient already exists: %s (%s)",
                 qPrintable(name),
                 qPrintable(query.lastError().text()));
        return {};
    }

    return coefficientId;
}

bool CoefficientsDatabase::updateCoefficient(const StringMap &data)
{
    if(data.isEmpty())
        return false;

    const QString name = data.value("name").toString().trimmed();
    if(name.isEmpty())
        return false;

    const QString coefficientId = data.value("id").toString().trimmed();
    if(coefficientId.isEmpty())
        return false;

    createCoefficientsTable();

    const int price = parsePriceCents(data.value("price"));
    QString unit = data.value("unit").toString().trimmed();
    if(unit.isEmpty())
        unit = QString::fromUtf8(kCoefficientUnit);
    QString keywords = data.value("keywords").toString().trimmed();
    if(keywords.isEmpty())
        keywords = keywordsFromName(name);

    const QString now = QDateTime::currentDateTime().toString(Qt::ISODate);

    QSqlDatabase db = openDatabase();
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "UPDATE coefficients SET name = ?, price = ?, unit = ?, keywords = ?, updated_at = ?"
        " WHERE id = ?"));
    query.addBindValue(name);
    query.addBindValue(price);
    query.addBindValue(unit);
    query.addBindValue(keywords);
    query.addBindValue(now);
    query.addBindValue(coefficientId);

    if(!query.exec())
    {
        qWarning("Coefficient name already exists: %s (%s)",
                 qPrintable(name),
                 qPrintable(query.lastError().text()));
        return false;
    }

    return query.numRowsAffected() > 0;
}

bool CoefficientsDatabase::deleteCoefficient(const QString &coefficientId)
{
    if(coefficientId.isEmpty())
        return false;

    QSqlDatabase db = openDatabase();
    QSqlQuery query(db);
    query.prepare(QStringLiteral("DELETE FROM coefficients WHERE id = ?"));
    query.addBindValue(coefficientId);
    if(!query.exec())
        return false;

    return query.numRowsAffected() > 0;
}

StringMapList CoefficientsDatabase::loadCoefficients()
{
    createCoefficientsTable();
    QSqlDatabase db = openDatabase();
    QSqlQuery query(db);
    query.exec(QStringLiteral(
        "SELECT id, name, price, unit, keywords, created_at, updated_at"
        " FROM coefficients ORDER BY name"));

    StringMapList result;
    while(query.next())
        result.append(rowToCoefficient(query));
    return result;
}

StringMap CoefficientsDatabase::getCoefficientById(const QString &coefficientId)
{
    QSqlDatabase db = openDatabase();
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "SELECT id, name, price, unit, keywords, created_at, updated_at"
        " FROM coefficients WHERE id = ?"));
    query.addBindValue(coefficientId);
    query.exec();

    if(query.next())
        return rowToCoefficient(query);

    return {};
}

StringMapList CoefficientsDatabase::searchCoefficients(const QString &queryText)
{
    if(queryText.trimmed().isEmpty())
        return loadCoefficients();

    const QString pattern = QStringLiteral("%%1%").arg(queryText.trimmed());
    QSqlDatabase db = openDatabase();
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "SELECT id, name, price, unit, keywords, created_at, updated_at"
        " FROM coefficients WHERE name LIKE ? OR keywords LIKE ? ORDER BY name"));
    query.addBindValue(pattern);
    query.addBindValue(pattern);
    query.exec();

    StringMapList result;
    while(query.next())
        result.append(rowToCoefficient(query));
    return result;
}

int CoefficientsDatabase::migratePercentServices()
{
    // Older builds kept coefficients as services with a percent unit.
    static bool migrated = false;
    if(migrated)
        return 0;
    migrated = true;

    QSqlDatabase db = openDatabase();
    QSqlQuery select(db);
    if(!select.exec(QStringLiteral(
            "SELECT id, name, price, unit, keywords, created_at, updated_at FROM services")))
    {
        // No services table yet: nothing to migrate.
        return 0;
    }

    StringMapList percentRows;
    QStringList legacyIds;
    while(select.next())
    {
        if(!ServiceUnits::isPercentUnit(select.value(3).toString()))
            continue;

        StringMap row;
        row.insert("id", select.value(0));
        row.insert("name", select.value(1));
        row.insert("price", select.value(2));
        row.insert("unit", select.value(3));
        row.insert("keywords", select.value(4));
        row.insert("created_at", select.value(5));
        row.insert("updated_at", select.value(6));
        percentRows.append(row);
        legacyIds.append(row.value("id").toString());
    }
    select.finish();

    if(percentRows.isEmpty())
        return 0;

    int moved = 0;
    db.transaction();
    for(const QVariant &item : percentRows)
    {
        const StringMap row = item.toMap();
        QSqlQuery insert(db);
        insert.prepare(QStringLiteral(
            "INSERT OR IGNORE INTO coefficients ("
            "id, name, price, unit, keywords, created_at, updated_at"
            ") VALUES (?, ?, ?, ?, ?, ?, ?)"));
        for(const QString &column : kCoefficientColumnsOrder)
            insert.addBindValue(row.value(column));
        if(insert.exec() && insert.numRowsAffected() > 0)
            ++moved;
    }

    for(const QString &legacyId : legacyIds)
    {
        QSqlQuery remove(db);
        remove.prepare(QStringLiteral("DELETE FROM services WHERE id = ?"));
        remove.addBindValue(legacyId);
        remove.exec();
    }
    db.commit();

    qInfo("CoefficientsDatabase: migrated %d coefficient rows out of the services table", moved);
    return moved;
}

} // namespace workorder
