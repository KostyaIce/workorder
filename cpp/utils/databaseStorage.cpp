#include "databaseStorage.h"

#include "appPaths.h"
#include "worksDatabase.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>

namespace workorder
{

QString DatabaseStorage::projectDataDir()
{
    return AppPaths::projectDataDir();
}

QString DatabaseStorage::defaultClientsDbPath()
{
    return QDir(projectDataDir()).filePath("clients.db");
}

QString DatabaseStorage::objectDbPath(const QString &clientName, const QString &clientId)
{
    return QDir(projectDataDir()).filePath(clientName + "_" + clientId + ".db");
}

QString DatabaseStorage::defaultSettingsPath()
{
    return QDir(projectDataDir()).filePath("app_settings.json");
}

QString DatabaseStorage::defaultReportsDir()
{
    return QDir(projectDataDir()).filePath("reports");
}

QString DatabaseStorage::resolveDbPath(const QString &filePath, const QString &defaultPath)
{
    if(!filePath.isEmpty())
        return QFileInfo(filePath).absoluteFilePath();
    return QFileInfo(defaultPath).absoluteFilePath();
}

QPair<QString, int> DatabaseStorage::createWorksDatabase(const QString &clientName, const QString &clientId)
{
    const QString path = objectDbPath(clientName, clientId);
    WorksDatabase::createWorksTable(clientName, clientId);
    return {QFileInfo(path).absoluteFilePath(), 0};
}

bool DatabaseStorage::addWorkEntry(const QString &clientName, const QString &clientId, const StringMap &data)
{
    if(data.isEmpty())
        return false;

    StringMap payload;
    payload.insert("object_id", data.value("object_id").toString());
    payload.insert("service_id", data.value("service_id").toString());
    payload.insert("subobject_name", data.value("subobject_name").toString());

    QString name = data.value("name").toString();
    if(name.isEmpty())
        name = data.value("service").toString();
    payload.insert("name", name);

    payload.insert("price", data.value("price", 0));
    payload.insert("unit", data.value("unit").toString());
    payload.insert("quantity", data.value("quantity", 1));
    payload.insert("coefficients", data.value("coefficients").toString());
    payload.insert("percent_sum", data.value("percent_sum", 100));

    return !WorksDatabase::addWork(clientName, clientId, payload).isEmpty();
}

StringMapList DatabaseStorage::loadWorks(const QString &clientName, const QString &clientId)
{
    return WorksDatabase::loadWorks(clientName, clientId);
}

bool DatabaseStorage::delWorkEntry(const QString &clientName, const QString &clientId, const StringMap &data)
{
    if(data.isEmpty())
        return false;

    const QString workId = data.value("id").toString();
    if(workId.isEmpty())
        return false;

    return WorksDatabase::deleteWork(clientName, clientId, workId);
}

bool DatabaseStorage::updateWorkEntry(const QString &clientName, const QString &clientId, const StringMap &data)
{
    if(data.isEmpty())
        return false;

    const QString workId = data.value("id").toString();
    if(workId.isEmpty())
        return false;

    StringMap payload;
    payload.insert("id", workId);

    const QStringList fields = {
        "object_id", "service_id", "subobject_name", "name", "price", "unit", "quantity",
        "start_order_at", "coefficients", "percent_sum",
    };
    for(const QString &field : fields)
    {
        if(data.contains(field))
            payload.insert(field, data.value(field));
    }

    if(data.contains("service") && !payload.contains("name"))
        payload.insert("name", data.value("service"));

    return WorksDatabase::updateWork(clientName, clientId, payload);
}

StringMap DatabaseStorage::loadAppSettings(const QString &filePath)
{
    const QString path = resolveDbPath(filePath, defaultSettingsPath());
    QFile file(path);
    if(!file.exists() || !file.open(QIODevice::ReadOnly))
        return {};

    const QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
    if(!doc.isObject())
        return {};

    return doc.object().toVariantMap();
}

QString DatabaseStorage::saveAppSettings(const StringMap &settings, const QString &filePath)
{
    const QString path = resolveDbPath(filePath, defaultSettingsPath());
    QDir().mkpath(QFileInfo(path).absolutePath());

    QFile file(path);
    if(!file.open(QIODevice::WriteOnly))
        return QString();

    const QJsonDocument doc(QJsonObject::fromVariantMap(settings));
    file.write(doc.toJson(QJsonDocument::Indented));
    return path;
}

} // namespace workorder
