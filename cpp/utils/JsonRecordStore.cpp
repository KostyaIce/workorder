#include "JsonRecordStore.h"

#include <QDebug>
#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QHash>
#include <QJsonDocument>
#include <QSaveFile>

namespace workorder
{

namespace
{

QJsonArray arrayFromDocument(const QJsonObject &document, const char *key)
{
    return document.value(QString::fromUtf8(key)).toArray();
}

} // namespace

bool JsonRecordStore::isJsonPayload(const QByteArray &payload)
{
    if(payload.isEmpty())
        return true;
    const char first = payload.trimmed().isEmpty() ? '\0' : payload.trimmed().at(0);
    return first == '{' || first == '[';
}

QJsonObject JsonRecordStore::loadDocument(const QString &filePath)
{
    QFile file(filePath);
    if(!file.exists())
        return {};

    if(!file.open(QIODevice::ReadOnly))
    {
        qWarning("JsonRecordStore::loadDocument failed to open %s", qPrintable(filePath));
        return {};
    }

    const QByteArray payload = file.readAll();
    file.close();
    if(!isJsonPayload(payload))
    {
        qWarning("JsonRecordStore::loadDocument non-JSON payload in %s", qPrintable(filePath));
        return {};
    }

    const QJsonDocument doc = QJsonDocument::fromJson(payload);
    if(!doc.isObject())
    {
        qWarning("JsonRecordStore::loadDocument invalid JSON object in %s", qPrintable(filePath));
        return {};
    }

    return doc.object();
}

bool JsonRecordStore::saveDocument(const QString &filePath, const QJsonObject &document)
{
    QDir().mkpath(QFileInfo(filePath).absolutePath());
    QSaveFile file(filePath);
    if(!file.open(QIODevice::WriteOnly))
    {
        qWarning("JsonRecordStore::saveDocument failed to open %s", qPrintable(filePath));
        return false;
    }

    const QByteArray payload = QJsonDocument(document).toJson(QJsonDocument::Compact);
    if(file.write(payload) != payload.size())
    {
        qWarning("JsonRecordStore::saveDocument incomplete write %s", qPrintable(filePath));
        return false;
    }

    return file.commit();
}

qint64 JsonRecordStore::recordRevision(const QJsonObject &record)
{
    const QJsonValue updated = record.value(QStringLiteral("updated_at"));
    const QJsonValue value = updated.isUndefined() || updated.isNull()
        ? record.value(QStringLiteral("created_at")) : updated;
    if(value.isDouble())
        return value.toVariant().toLongLong() * 1000;
    const QString text = value.toString();
    const QDateTime date = QDateTime::fromString(text, Qt::ISODateWithMs);
    if(date.isValid())
        return date.toMSecsSinceEpoch();
    return text.toLongLong() * 1000;
}

bool JsonRecordStore::documentsEqual(const QJsonObject &left, const QJsonObject &right)
{
    if(left.keys() != right.keys())
        return false;
    for(auto it = left.begin(); it != left.end(); ++it)
    {
        const QJsonValue other = right.value(it.key());
        if(!it.value().isArray() || !other.isArray())
        {
            if(it.value() != other)
                return false;
            continue;
        }
        QMap<QString, QJsonObject> a, b;
        auto index = [](const QJsonArray &records, QMap<QString, QJsonObject> &result)
        {
            for(const auto &value : records)
            {
                const QJsonObject record = value.toObject();
                const QString id = record.value(QStringLiteral("id")).toString();
                if(id.isEmpty() || result.contains(id))
                    return false;
                result.insert(id, record);
            }
            return true;
        };
        if(!index(it.value().toArray(), a) || !index(other.toArray(), b) || a != b)
            return false;
    }
    return true;
}

JsonMergeResult JsonRecordStore::mergeByLatestRevision(const QJsonArray &localRecords,
                                                       const QJsonArray &remoteRecords)
{
    JsonMergeResult result;
    QHash<QString, QJsonObject> mergedById;
    mergedById.reserve(localRecords.size() + remoteRecords.size());

    auto ingest = [&](const QJsonArray &records, bool remoteSide)
    {
        for(const QJsonValue &value : records)
        {
            if(!value.isObject())
                continue;
            const QJsonObject record = value.toObject();
            const QString id = record.value(QStringLiteral("id")).toString();
            if(id.isEmpty())
                continue;

            if(!mergedById.contains(id))
            {
                mergedById.insert(id, record);
                if(remoteSide)
                    ++result.added;
                continue;
            }

            const QJsonObject existing = mergedById.value(id);
            const qint64 existingRevision = recordRevision(existing);
            const qint64 incomingRevision = recordRevision(record);
            if(incomingRevision > existingRevision && record != existing)
            {
                mergedById.insert(id, record);
                if(remoteSide)
                    ++result.updated;
            }
        }
    };

    ingest(localRecords, false);
    ingest(remoteRecords, true);

    result.merged = QJsonArray();
    for(auto it = mergedById.constBegin(); it != mergedById.constEnd(); ++it)
        result.merged.append(it.value());

    return result;
}

QJsonObject JsonRecordStore::recordFromMap(const StringMap &map)
{
    QJsonObject object;
    for(auto it = map.constBegin(); it != map.constEnd(); ++it)
        object.insert(it.key(), QJsonValue::fromVariant(it.value()));
    return object;
}

StringMap JsonRecordStore::recordToMap(const QJsonObject &record)
{
    StringMap map;
    for(auto it = record.constBegin(); it != record.constEnd(); ++it)
        map.insert(it.key(), it.value().toVariant());
    return map;
}

int JsonRecordStore::findRecordIndex(QJsonArray &records, const QString &id)
{
    for(int index = 0; index < records.size(); ++index)
    {
        const QJsonObject record = records.at(index).toObject();
        if(record.value(QStringLiteral("id")).toString() == id)
            return index;
    }
    return -1;
}

} // namespace workorder
