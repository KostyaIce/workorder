#include "ClientDbDocument.h"

#include "DatabaseStorage.h"
#include "JsonRecordStore.h"

namespace workorder
{

QJsonObject ClientDbDocument::emptyDocument()
{
    QJsonObject document;
    document.insert(QStringLiteral("objects"), QJsonArray());
    document.insert(QStringLiteral("completed_works"), QJsonArray());
    document.insert(QStringLiteral("expenses"), QJsonArray());
    return document;
}

QString ClientDbDocument::filePath(const QString &clientName, const QString &clientId)
{
    return DatabaseStorage::objectDbPath(clientName, clientId);
}

QJsonObject ClientDbDocument::loadFile(const QString &filePath)
{
    QJsonObject document = JsonRecordStore::loadDocument(filePath);
    if(document.isEmpty())
        return emptyDocument();

    if(!document.contains(QStringLiteral("objects")))
        document.insert(QStringLiteral("objects"), QJsonArray());
    if(!document.contains(QStringLiteral("completed_works")))
        document.insert(QStringLiteral("completed_works"), QJsonArray());
    if(!document.contains(QStringLiteral("expenses")))
        document.insert(QStringLiteral("expenses"), QJsonArray());
    return document;
}

QJsonObject ClientDbDocument::load(const QString &clientName, const QString &clientId)
{
    return loadFile(filePath(clientName, clientId));
}

bool ClientDbDocument::saveFile(const QString &filePath, const QJsonObject &document)
{
    return JsonRecordStore::saveDocument(filePath, document);
}

bool ClientDbDocument::save(const QString &clientName, const QString &clientId, const QJsonObject &document)
{
    return saveFile(filePath(clientName, clientId), document);
}

QJsonArray ClientDbDocument::objectsArray(const QJsonObject &document)
{
    return document.value(QStringLiteral("objects")).toArray();
}

QJsonArray ClientDbDocument::worksArray(const QJsonObject &document)
{
    return document.value(QStringLiteral("completed_works")).toArray();
}

QJsonArray ClientDbDocument::expensesArray(const QJsonObject &document)
{
    return document.value(QStringLiteral("expenses")).toArray();
}

} // namespace workorder
