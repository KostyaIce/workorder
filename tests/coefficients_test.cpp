// Standalone check for the separate coefficients table, its migration from the
// legacy services rows and the Excel section round trip.
// Build example (macOS):
//   clang++ -std=c++17 tests/coefficients_test.cpp build-cpp/cpp/utils/libworkorder_utils.a ...
#include "CoefficientsDatabase.h"
#include "ServicesDatabase.h"
#include "ServicesExcelBuilder.h"

#include <QCoreApplication>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QTemporaryDir>

#include <cstdio>
#include <cstdlib>

using namespace workorder;

static void checkImpl(bool ok, int line)
{
    if(!ok)
    {
        fprintf(stderr, "CHECK failed at line %d\n", line);
        std::abort();
    }
}

#define check(expr) checkImpl((expr), __LINE__)

static void insertLegacyService(const QString &id, const QString &name, int price, const QString &unit)
{
    QSqlDatabase db = QSqlDatabase::database(QStringLiteral("services"));
    QSqlQuery query(db);
    query.prepare(QStringLiteral(
        "INSERT INTO services(id, name, note, paragraph, price, unit, keywords, created_at, updated_at)"
        " VALUES(?, ?, '', '', ?, ?, '', '2026-01-01T00:00:00', '2026-01-01T00:00:00')"));
    query.addBindValue(id);
    query.addBindValue(name);
    query.addBindValue(price);
    query.addBindValue(unit);
    check(query.exec());
}

int main(int argc, char **argv)
{
    QTemporaryDir dir;
    check(dir.isValid());
    qputenv("WORKORDER_DATA_DIR", dir.path().toUtf8());
    QCoreApplication app(argc, argv);

    // Legacy layout: coefficients lived in the services table with a percent unit.
    ServicesDatabase::createServicesTable();
    insertLegacyService("s1", QStringLiteral("Монтаж"), 50000, QStringLiteral("шт"));
    insertLegacyService("c1", QStringLiteral("Стеснённые условия"), 15000, QStringLiteral("%"));

    CoefficientsDatabase::createCoefficientsTable();

    const StringMapList services = ServicesDatabase::loadServices();
    check(services.size() == 1);
    check(services.first().toMap().value("name").toString() == QStringLiteral("Монтаж"));

    const StringMapList migrated = CoefficientsDatabase::loadCoefficients();
    check(migrated.size() == 1);
    check(migrated.first().toMap().value("id").toString() == QLatin1String("c1"));
    check(migrated.first().toMap().value("price").toInt() == 15000);
    check(migrated.first().toMap().value("unit").toString() == QLatin1String("%"));

    // CRUD on the new table.
    StringMap created;
    created.insert("name", QStringLiteral("Высотные работы"));
    created.insert("price", QStringLiteral("120"));
    const QString coefficientId = CoefficientsDatabase::addCoefficient(created);
    check(!coefficientId.isEmpty());
    check(CoefficientsDatabase::loadCoefficients().size() == 2);

    StringMap duplicate;
    duplicate.insert("name", QStringLiteral("Высотные работы"));
    duplicate.insert("price", QStringLiteral("110"));
    check(CoefficientsDatabase::addCoefficient(duplicate).isEmpty());

    StringMap updated;
    updated.insert("id", coefficientId);
    updated.insert("name", QStringLiteral("Высотные работы"));
    updated.insert("price", QStringLiteral("135"));
    check(CoefficientsDatabase::updateCoefficient(updated));
    check(CoefficientsDatabase::getCoefficientById(coefficientId).value("price").toInt() == 13500);
    check(CoefficientsDatabase::searchCoefficients(QStringLiteral("высот")).size() == 1);

    // Excel: coefficients are exported as their own section and imported back.
    const QString catalogPath = dir.filePath("catalog.xlsx");
    ExcelCatalog catalog;
    catalog.services = ServicesDatabase::loadServices();
    catalog.coefficients = CoefficientsDatabase::loadCoefficients();
    check(!exportCatalogExcel(catalogPath, catalog).isEmpty());

    const ExcelCatalog imported = importCatalogFromExcel(catalogPath);
    check(imported.services.size() == 1);
    check(imported.services.first().toMap().value("name").toString() == QStringLiteral("Монтаж"));
    check(imported.coefficients.size() == 2);

    int foundStesnennye = 0;
    int foundVysotnye = 0;
    for(const QVariant &item : imported.coefficients)
    {
        const StringMap row = item.toMap();
        const QString name = row.value("name").toString();
        if(name == QStringLiteral("Стеснённые условия"))
        {
            ++foundStesnennye;
            // 150% is stored as percent * 100.
            check(ServicesDatabase::parsePriceCents(row.value("price")) == 15000);
            check(row.value("unit").toString() == QLatin1String("%"));
        }
        else if(name == QStringLiteral("Высотные работы"))
        {
            ++foundVysotnye;
            check(ServicesDatabase::parsePriceCents(row.value("price")) == 13500);
        }
    }
    check(foundStesnennye == 1);
    check(foundVysotnye == 1);

    // A workbook without the section still routes percent rows to coefficients.
    const QString legacyPath = dir.filePath("legacy.xlsx");
    ExcelCatalog legacy;
    StringMap legacyCoefficient;
    legacyCoefficient.insert("name", QStringLiteral("Ночные работы"));
    legacyCoefficient.insert("price", 11000);
    legacyCoefficient.insert("unit", QStringLiteral("%"));
    legacy.services.append(legacyCoefficient);
    check(!exportCatalogExcel(legacyPath, legacy).isEmpty());

    const ExcelCatalog legacyImported = importCatalogFromExcel(legacyPath);
    check(legacyImported.services.isEmpty());
    check(legacyImported.coefficients.size() == 1);
    check(legacyImported.coefficients.first().toMap().value("name").toString()
          == QStringLiteral("Ночные работы"));

    check(CoefficientsDatabase::deleteCoefficient(coefficientId));
    check(CoefficientsDatabase::loadCoefficients().size() == 1);

    QSqlDatabase::removeDatabase(QStringLiteral("services"));
    return 0;
}
