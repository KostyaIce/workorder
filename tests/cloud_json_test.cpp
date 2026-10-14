#include "JsonRecordStore.h"
#include "DatabaseCloudJson.h"
#include "ClientsDatabase.h"
#include <QCoreApplication>
#include <QTemporaryDir>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <cstdlib>

using namespace workorder;

static void check(bool ok) { if(!ok) std::abort(); }

int main(int argc, char **argv)
{
    QCoreApplication app(argc, argv);
    const QJsonObject local{{"id", "a"}, {"updated_at", "2026-10-14T12:00:00.100Z"}, {"name", "local"}};
    QJsonObject remote = local;
    remote["name"] = "remote";
    check(JsonRecordStore::mergeByLatestRevision({local}, {remote}).merged.first() == local);
    remote["updated_at"] = "2026-10-14T12:00:00.101Z";
    check(JsonRecordStore::mergeByLatestRevision({local}, {remote}).merged.first() == remote);
    remote["updated_at"] = "2026-10-14T11:59:59Z";
    check(JsonRecordStore::mergeByLatestRevision({local}, {remote}).merged.first() == local);
    const QJsonObject other{{"id", "b"}, {"updated_at", 123}};
    check(JsonRecordStore::documentsEqual({{"rows", QJsonArray{local, other}}},
                                         {{"rows", QJsonArray{other, local}}}));
    check(!JsonRecordStore::documentsEqual({{"rows", QJsonArray{local}}},
                                          {{"rows", QJsonArray{remote}}}));
    check(JsonRecordStore::recordRevision({{"updated_at", 1}}) == 1000);
    check(JsonRecordStore::recordRevision({{"updated_at", "1970-01-01T00:00:01Z"}}) == 1000);

    QTemporaryDir dir;
    check(dir.isValid());
    const QString dbPath = dir.filePath("clients.db");
    const QString jsonPath = dir.filePath("clients.json");
    // Exercise migration of an existing schema, then a real SQLite/JSON round trip.
    auto db = QSqlDatabase::addDatabase("QSQLITE", "test_legacy");
    db.setDatabaseName(dbPath);
    check(db.open());
    QSqlQuery query(db);
    check(query.exec("CREATE TABLE clients(id TEXT PRIMARY KEY, kind TEXT, name TEXT, address TEXT, contact TEXT, notes TEXT, created_at TEXT)"));
    check(query.exec("INSERT INTO clients VALUES('a','person','old','','','','2020-01-01T00:00:00Z')"));
    check(DatabaseCloudJson::exportClientsToJsonFile(dbPath, jsonPath));
    auto document = JsonRecordStore::loadDocument(jsonPath);
    auto record = document["clients"].toArray().first().toObject();
    check(record["updated_at"] == record["created_at"]);
    record["updated_at"] = "2026-10-14T12:00:00.101Z";
    record["name"] = "new";
    document["clients"] = QJsonArray{record};
    check(JsonRecordStore::saveDocument(jsonPath, document));
    check(DatabaseCloudJson::mergeClientsFromJsonFile(jsonPath, dbPath) == 0);
    check(DatabaseCloudJson::exportClientsToJsonFile(dbPath, jsonPath));
    check(JsonRecordStore::documentsEqual(document, JsonRecordStore::loadDocument(jsonPath)));
    check(JsonRecordStore::saveDocument(jsonPath, {{"clients", QJsonArray{record, record}}}));
    check(DatabaseCloudJson::mergeClientsFromJsonFile(jsonPath, dbPath) == -1);
    return 0;
}
