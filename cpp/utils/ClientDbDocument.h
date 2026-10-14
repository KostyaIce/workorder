#ifndef WORKORDER_UTILS_CLIENT_DB_DOCUMENT_H
#define WORKORDER_UTILS_CLIENT_DB_DOCUMENT_H

#include <QJsonArray>
#include <QJsonObject>
#include <QString>

namespace workorder
{

class ClientDbDocument
{
public:
    static QString filePath(const QString &clientName, const QString &clientId);
    static QJsonObject load(const QString &clientName, const QString &clientId);
    static QJsonObject loadFile(const QString &filePath);
    static bool save(const QString &clientName, const QString &clientId, const QJsonObject &document);
    static bool saveFile(const QString &filePath, const QJsonObject &document);
    static QJsonObject emptyDocument();
    static QJsonArray objectsArray(const QJsonObject &document);
    static QJsonArray worksArray(const QJsonObject &document);
    static QJsonArray expensesArray(const QJsonObject &document);
};

} // namespace workorder

#endif // WORKORDER_UTILS_CLIENT_DB_DOCUMENT_H
