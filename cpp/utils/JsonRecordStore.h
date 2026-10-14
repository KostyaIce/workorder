#ifndef WORKORDER_UTILS_JSON_RECORD_STORE_H
#define WORKORDER_UTILS_JSON_RECORD_STORE_H

#include "Types.h"

#include <QJsonArray>
#include <QJsonObject>
#include <QString>

namespace workorder
{

struct JsonMergeResult
{
    QJsonArray merged;
    int added = 0;
    int updated = 0;
};

class JsonRecordStore
{
public:
    static QJsonObject loadDocument(const QString &filePath);
    static bool saveDocument(const QString &filePath, const QJsonObject &document);
    static bool isJsonPayload(const QByteArray &payload);
    static bool documentsEqual(const QJsonObject &left, const QJsonObject &right);
    static qint64 recordRevision(const QJsonObject &record);
    static JsonMergeResult mergeByLatestRevision(const QJsonArray &localRecords,
                                                 const QJsonArray &remoteRecords);
    static QJsonObject recordFromMap(const StringMap &map);
    static StringMap recordToMap(const QJsonObject &record);
    static int findRecordIndex(QJsonArray &records, const QString &id);
};

} // namespace workorder

#endif // WORKORDER_UTILS_JSON_RECORD_STORE_H
