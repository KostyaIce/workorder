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

static QJsonObject firstClient(const QString &jsonPath)
{
    return JsonRecordStore::loadDocument(jsonPath)
        .value(QStringLiteral("clients")).toArray().first().toObject();
}

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

    // Integer revisions are used by objects, works and expenses.
    const QJsonObject intLocal{{"id", "o"}, {"updated_at", 100}, {"name", "local"}};
    QJsonObject intRemote = intLocal;
    intRemote["updated_at"] = 101;
    intRemote["name"] = "remote";
    check(JsonRecordStore::mergeByLatestRevision({intLocal}, {intRemote}).merged.first() == intRemote);
    intRemote["updated_at"] = 99;
    check(JsonRecordStore::mergeByLatestRevision({intLocal}, {intRemote}).merged.first() == intLocal);

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
    ClientsDatabase::createClientTable(dbPath);
    StringMap client;
    client.insert("kind", "customer");
    client.insert("name", "Local");
    client.insert("phone", "+70000000000");
    client.insert("address", "A");
    client.insert("email", "local@example.com");
    check(!ClientsDatabase::addClientEntry(client, dbPath).isEmpty());
    check(DatabaseCloudJson::exportClientsToJsonFile(dbPath, jsonPath));

    QJsonObject record = firstClient(jsonPath);
    check(record.value("name").toString() == "Local");

    // Remote is newer: the local row must be replaced.
    QJsonObject newer = record;
    newer["updated_at"] = "2099-01-01T00:00:00.000Z";
    newer["name"] = "Remote";
    check(JsonRecordStore::saveDocument(jsonPath, {{"clients", QJsonArray{newer}}}));
    check(DatabaseCloudJson::mergeClientsFromJsonFile(jsonPath, dbPath) == 0);
    check(DatabaseCloudJson::exportClientsToJsonFile(dbPath, jsonPath));
    check(firstClient(jsonPath).value("name").toString() == "Remote");

    // Remote is older: the local row must win and be exported back.
    QJsonObject older = record;
    older["updated_at"] = "2000-01-01T00:00:00.000Z";
    older["name"] = "Stale";
    check(JsonRecordStore::saveDocument(jsonPath, {{"clients", QJsonArray{older}}}));
    check(DatabaseCloudJson::mergeClientsFromJsonFile(jsonPath, dbPath) == 0);
    check(DatabaseCloudJson::exportClientsToJsonFile(dbPath, jsonPath));
    check(firstClient(jsonPath).value("name").toString() == "Remote");

    // A new remote id is added to the local database.
    QJsonObject added = newer;
    added["id"] = "new-client";
    added["name"] = "Added";
    check(JsonRecordStore::saveDocument(jsonPath, {{"clients", QJsonArray{added}}}));
    check(DatabaseCloudJson::mergeClientsFromJsonFile(jsonPath, dbPath) == 1);
    check(DatabaseCloudJson::exportClientsToJsonFile(dbPath, jsonPath));
    check(JsonRecordStore::loadDocument(jsonPath).value("clients").toArray().size() == 2);

    // Invalid rows make the writer fail; the caller must get -1, not "0 changes".
    QJsonObject invalid = added;
    invalid["id"] = "invalid-client";
    invalid["phone"] = "";
    check(JsonRecordStore::saveDocument(jsonPath, {{"clients", QJsonArray{invalid}}}));
    check(DatabaseCloudJson::mergeClientsFromJsonFile(jsonPath, dbPath) == -1);

    QSqlDatabase::removeDatabase(QStringLiteral("clients_%1").arg(dbPath));
    return 0;
}
